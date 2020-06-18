# Flutter Darwin Notification Plugin

A iOS Darwin Notification plugin for Flutter. This plugin provides a cross-platform (iOS, Android) API to request and call native darwin notification center.

![Flutter Test](https://github.com/Modool/flutter_darwin_notification/workflows/Flutter%20Test/badge.svg) [![pub package](https://img.shields.io/pub/v/flutter_darwin_notification.svg)](https://pub.dartlang.org/packages/flutter_darwin_notification) [![Build Status](https://app.bitrise.io/app/fa4f5d4bf452bcfb/status.svg?token=HorGpL_AOw2llYz39CjmdQ&branch=master)](https://app.bitrise.io/app/fa4f5d4bf452bcfb) [![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://github.com/tenhobi/effective_dart)

## Features

* Darwin notification center plugin for ios.
* Support to send notification to darwin notification center.

## Usage

To use this plugin, add `flutter_darwin_notification` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_darwin_notification: 0.0.1
```

## API

```dart

import 'package:flutter_darwin_notification/flutter_darwin_notification.dart';

/// New instance
final center = DarwinNotificationCenter();

/// Observe notification 
final stream = center.observe(name: 'notification-name', behavior: Behavior.coalesce);
stream.listen((result) {
  /// Do something    
});

/// Post notification 
center.postNotification('notification-name', object: '1', userInfo: {'1': '2'});

```

## Issues

Please file any issues, bugs or feature request as an issue on our [Github](https://github.com/modool/flutter_darwin_notification/issues) page.

## Want to contribute

If you would like to contribute to the plugin (e.g. by improving the documentation, solving a bug or adding a cool new feature), please carefully review our [contribution guide](CONTRIBUTING.md) and send us your [pull request](https://github.com/modool/flutter_cache/pulls).

## Author

This Flutter object cache package for Flutter is developed by [modool](https://github.com/modool). You can contact us at <modool.go@gmail.com>
