import 'package:flutter_darwin_notification/flutter_darwin_notification.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel =
      MethodChannel('modool.github.com/plugins/darwin_notification');

  final notificationCenter = DarwinNotificationCenter();
  final log = <MethodCall>[];

  setUpAll(() {
    channel.setMockMethodCallHandler((methodCall) async {
      log.add(methodCall);

      return true;
    });
  });

  tearDownAll(() {
    channel.setMockMethodCallHandler(null);
  });

  tearDown(() {
    notificationCenter.dispose();
    log.clear();
  });

  group('invoke', () {
    tearDown(() {
      notificationCenter.dispose();
      log.clear();
    });

    test('observe notification with name', () async {
      final stream = notificationCenter.observe(name: 'name');
      expect(stream, isNotNull);

      final subscription = stream.listen((_) {});
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'addObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          )
        ],
      );
      expect(subscription, isNotNull);
    });

    test('observe notification with name and behavior', () async {
      final stream =
          notificationCenter.observe(name: 'name', behavior: Behavior.coalesce);
      expect(stream, isNotNull);

      final subscription = stream.listen((_) {});
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'addObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.coalesce.index,
            },
          )
        ],
      );

      expect(subscription, isNotNull);
    });

    test('post notification', () async {
      final success = await notificationCenter
          .postNotification('name', string: '1', userInfo: {'1': '2'});
      expect(success, true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'postNotification',
            arguments: {
              'name': 'name',
              'string': '1',
              'userInfo': {'1': '2'},
              'deliverImmediately': true,
              'options': 0,
            },
          )
        ],
      );
    });

    test('remove observers with name ', () async {
      final stream = notificationCenter.observe(name: 'name');
      expect(stream, isNotNull);

      final subscription = stream.listen((_) {});
      expect(subscription, isNotNull);

      await subscription.cancel();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'addObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          ),
          isMethodCall(
            'removeObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          )
        ],
      );
    });

    test('remove observer with name and behavior', () async {
      final stream = notificationCenter.observe(
          name: 'name', behavior: Behavior.deliverImmediately);
      expect(stream, isNotNull);

      final subscription = stream.listen((_) {});
      expect(subscription, isNotNull);

      await subscription.cancel();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'addObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          ),
          isMethodCall(
            'removeObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          )
        ],
      );
    });

    test('remove all observers', () async {
      final stream = notificationCenter.observe(name: 'name');
      expect(stream, isNotNull);

      final subscription1 = stream.listen((_) {});
      expect(subscription1, isNotNull);

      final stream2 = notificationCenter.observe(
          name: 'name', behavior: Behavior.deliverImmediately);
      expect(stream2, isNotNull);

      final subscription2 = stream2.listen((_) {});
      expect(subscription2, isNotNull);

      await notificationCenter.dispose();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'addObserver',
            arguments: {
              'name': 'name',
              'behavior': Behavior.deliverImmediately.index,
            },
          ),
          isMethodCall(
            'removeAllObservers',
            arguments: null,
          ),
        ],
      );
    });
  });

  group('receive notifications', () {
    tearDown(() {
      notificationCenter.dispose();
      log.clear();
    });

    test('for all behavior', () async {
      final stream = notificationCenter.observe(name: 'name');
      expect(stream, isNotNull);

      stream.listen(
        expectAsync1(
          (result) {
            expect(result.string, '1');
            expect(result.userInfo(), {'1': 1});
          },
        ),
      );

      await channel.binaryMessenger.handlePlatformMessage(
        'modool.github.com/plugins/darwin_notification',
        channel.codec.encodeMethodCall(
          MethodCall(
            'receiveNotification',
            {
              'name': 'name',
              'string': '1',
              'behavior': Behavior.deliverImmediately.index,
              'userInfo': const {'1': 1},
            },
          ),
        ),
        (data) {},
      );
    });

    test('receive notification for Behavior.deliverImmediately', () async {
      final stream =
          notificationCenter.observe(name: 'name', behavior: Behavior.coalesce);
      expect(stream, isNotNull);

      stream.listen(
        expectAsync1(
          (result) {
            expect(result.string, '1');
            expect(result.userInfo(), {'1': 1});
          },
        ),
      );

      await channel.binaryMessenger.handlePlatformMessage(
        'modool.github.com/plugins/darwin_notification',
        channel.codec.encodeMethodCall(
          MethodCall(
            'receiveNotification',
            {
              'name': 'name',
              'string': '1',
              'behavior': Behavior.coalesce.index,
              'userInfo': const {'1': 1},
            },
          ),
        ),
        (data) {},
      );
    });

    test('receive notification for no behavior', () async {
      final stream =
          notificationCenter.observe(name: 'name', behavior: Behavior.coalesce);
      expect(stream, isNotNull);

      try {
        await channel.binaryMessenger.handlePlatformMessage(
          'modool.github.com/plugins/darwin_notification',
          channel.codec.encodeMethodCall(
            MethodCall(
              'receiveNotification',
              {
                'name': 'name',
                'string': '1',
                'userInfo': {'1': 1},
              },
            ),
          ),
          (data) {},
        );
      } on Exception catch (e) {
        expect(e.toString().contains('Received unknown behavior notificaiton'),
            true);
      }
    });
  });
}
