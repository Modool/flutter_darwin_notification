import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Behavior {
  @deprecated
  none,
// The server will not queue any notifications with this name and object while the process/app is in the background.
  drop,
// The server will only queue the last notification of the specified name and object; earlier notifications are dropped.
  coalesce,
// The server will hold all matching notifications until the queue has been filled (queue size determined by the server) at which point the server may flush queued notifications.
  hold,
// The server will deliver notifications matching this registration whether or not the process is in the background.  When a notification with this suspension behavior is matched, it has the effect of first flushing any queued notifications.
  deliverImmediately,
}

class Result {
  Result(this._object, this._userInfo);

  final dynamic _object;
  T object<T>() {
    // ignore: avoid_as
    return _object as T;
  }

  final dynamic _userInfo;
  T userInfo<T>() {
    // ignore: avoid_as
    return _userInfo as T;
  }
}

class _Observer {
  _Observer(this.name, this._channel);

  final String name;
  final MethodChannel _channel;

  final _streamControllers = <Behavior, StreamController<Result>>{};
  final _states = <Behavior, bool>{};

  void add(Result result, Behavior behavior) {
    // ignore: close_sinks
    final streamController = streamControllerForBehavior(behavior);
    if (streamController != null) {
      streamController.add(result);
    }
  }

  StreamController<Result> streamControllerForBehavior(Behavior behavior,
      {bool createIfNotExist}) {
    var streamController = _streamControllers[behavior];
    if (streamController == null && createIfNotExist) {
      streamController = StreamController<Result>.broadcast(
        onCancel: () => _onCancel(behavior),
        onListen: () => _onListen(behavior),
      );

      _streamControllers[behavior] = streamController;
    }
    return streamController;
  }

  void _onListen(Behavior behavior) {
    final registered = _states[behavior] ?? false;
    if (registered) return;

    _addObserver(behavior);
    _states[behavior] = true;
  }

  void _onCancel(Behavior behavior) {
    // ignore: close_sinks
    final streamController = _streamControllers[behavior];
    if (streamController.hasListener) return;

    final registered = _states[behavior] ?? false;
    if (!registered) return;

    _states.remove(behavior);
    _streamControllers.remove(behavior);
    _removeObserver(behavior: behavior);
  }

  void _addObserver(Behavior behavior) {
    final args = <String, dynamic>{'name': name, 'behavior': behavior.index};

    _channel.invokeMethod<bool>('addObserver', args);
  }

  Future<void> _removeObserver({Behavior behavior}) async {
    final args = <String, dynamic>{'name': name};
    if (behavior != null) {
      args['behavior'] = behavior.index;
    }

    await _channel.invokeMethod('removeObserver', args);
  }

  Future<void> dispose() async {
    _states.clear();

    _streamControllers.values.forEach((streamController) async {
      await streamController.close();
    });
  }
}

class DarwinNotificationCenter {
  DarwinNotificationCenter() {
    _channel = MethodChannel(
      'modool.github.com/plugins/darwin_notification',
    );
    _channel.setMethodCallHandler(_onMethodCallback);
  }

  MethodChannel _channel;

  /// Hash code to observer
  final _observers = <String, _Observer>{};

  StreamController<Result> _findStreamController(String name, Behavior behavior,
      {bool createIfNotExist}) {
    var observer = _observers[name];
    if (observer == null) {
      if (createIfNotExist) {
        observer = _Observer(name, _channel);
        _observers[name] = observer;
      } else {
        return null;
      }
    }

    return observer.streamControllerForBehavior(behavior,
        createIfNotExist: createIfNotExist);
  }

  Stream<Result> observe({
    @required String name,
    Behavior behavior = Behavior.deliverImmediately,
  }) =>
      _findStreamController(name, behavior, createIfNotExist: true).stream;

  // If center is a Darwin notification center, this value is ignored. So, object and userInfo can be delete
  Future<bool> postNotification(
    String name, {
    object,
    Map<String, dynamic> userInfo,
    bool deliverImmediately = true,
    int options = 0,
  }) {
    return _channel.invokeMethod<bool>('postNotification', {
      'name': name,
      'object': object,
      'userInfo': userInfo,
      'deliverImmediately': deliverImmediately,
      'options': options,
    });
  }

  Future<void> _onMethodCallback(MethodCall call) async {
    switch (call.method) {
      case 'receiveNotification':
        _onReceiveNotification(call.arguments);
        break;
      default:
        break;
    }
  }

  void _onReceiveNotification(Map arguments) {
    if (_observers.isEmpty) return;

    final observer = _observers[arguments['name']];
    if (observer == null) return;

    final object = arguments['object'];
    final userInfo = arguments['userInfo'];
    final result = Result(object, userInfo);

    final index = arguments['behavior'];
    if (index == null) {
      throw Exception('Received unknown behavior notification: $result.');
    }
    final behavior = Behavior.values[index];
    observer.add(result, behavior);
  }

  Future<void> dispose() async {
    _observers.values.forEach((observer) async {
      await observer.dispose();
    });
    _observers.clear();

    await _channel.invokeMethod('removeAllObservers');
  }
}
