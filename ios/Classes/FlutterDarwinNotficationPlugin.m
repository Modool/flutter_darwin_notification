#import "FlutterDarwinNotficationPlugin.h"

static NSString * const FlutterDarwinNotficationPost = @"postNotification";
static NSString * const FlutterDarwinNotficationAddObserver = @"addObserver";
static NSString * const FlutterDarwinNotficationRemoveObserver = @"removeObserver";
static NSString * const FlutterDarwinNotficationRemoveAllObservers = @"removeAllObservers";
static NSString * const FlutterDarwinNotficationReceiveNotification = @"receiveNotification";

static FlutterMethodChannel *channel;

@implementation FlutterDarwinNotficationPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:@"modool.github.com/plugins/darwin_notification"
               binaryMessenger:[registrar messenger]];
    FlutterDarwinNotficationPlugin* instance = [[FlutterDarwinNotficationPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    if ([FlutterDarwinNotficationAddObserver isEqualToString:call.method]) {
        error = [self _addObserverWithName:args[@"name"] behavior:[args[@"behavior"] integerValue]];
    } else if ([FlutterDarwinNotficationPost isEqualToString:call.method]) {
        CFOptionFlags options = [args[@"options"] unsignedIntValue];
        if (options == 0) {
            [self _postNotificationWithName:args[@"name"] object:args[@"object"] userInfo:args[@"userInfo"] deliverImmediately:[args[@"deliverImmediately"] boolValue]];
        } else {
            [self _postNotificationWithName:args[@"name"] object:args[@"object"] userInfo:args[@"userInfo"] options:options];
        }
    } else if ([FlutterDarwinNotficationRemoveObserver isEqual:call.method]) {
        [self _removeObserverWithName:args[@"name"] ];
    } else if ([FlutterDarwinNotficationRemoveAllObservers isEqual:call.method]) {
        [self _removeAllObservers];
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
    result(error);
}

- (FlutterError *)_addObserverWithName:(NSString *)name behavior:(CFNotificationSuspensionBehavior)behavior {
    if (!name || name.length <= 0) return [FlutterError errorWithCode:@"0" message:@"Notification name can't be nil." details:nil];
    
    void (* func)(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
    
    switch (behavior) {
        case CFNotificationSuspensionBehaviorDrop: func = onBehaviorDropping; break;
        case CFNotificationSuspensionBehaviorCoalesce: func = onBehaviorCoalescing; break;
        case CFNotificationSuspensionBehaviorHold: func = onBehaviorHolding; break;
        case CFNotificationSuspensionBehaviorDeliverImmediately: func = onBehaviorDeliverringImmediately; break;
        default: return [FlutterError errorWithCode:@"0" message:[NSString stringWithFormat:@"Unknown behavior: %lu for notification: %@", behavior, name] details:nil];
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), func, (__bridge CFNotificationName)name, NULL, behavior);
    
    return nil;
}

- (void)_postNotificationWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately {
    if (!name || !name.length) return;
    // If center is a Darwin notification center, this value is ignored. 根据官方文档，当通知类型为darwin时，只能收发通知，无法进行传值
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFNotificationName)name, (const void *)object, (__bridge CFDictionaryRef)userInfo, deliverImmediately);
}

- (void)_postNotificationWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo options:(CFOptionFlags)options {
    if (!name || !name.length) return;
    // If center is a Darwin notification center, this value is ignored. 根据官方文档，当通知类型为darwin时，只能收发通知，无法进行传值
    CFNotificationCenterPostNotificationWithOptions(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFNotificationName)name, (const void *)object, (__bridge CFDictionaryRef)userInfo, options);
}

- (void)_removeObserverWithName:(NSString *)name {
    if (!name || !name.length) return;
    
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), (__bridge CFNotificationName)name, NULL);
}

- (void)_removeAllObservers {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)self);
}

#pragma mark - replay

//CFNotificationSuspensionBehaviorDrop = 1,
//    // The server will not queue any notifications with this name and object while the process/app is in the background.
//CFNotificationSuspensionBehaviorCoalesce = 2,
//    // The server will only queue the last notification of the specified name and object; earlier notifications are dropped.
//CFNotificationSuspensionBehaviorHold = 3,
//    // The server will hold all matching notifications until the queue has been filled (queue size determined by the server) at which point the server may flush queued notifications.
//CFNotificationSuspensionBehaviorDeliverImmediately = 4
static void onBehaviorDropping(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    onDarwinNotificationCallback(center, observer, name, object, userInfo, CFNotificationSuspensionBehaviorDrop);
}

static void onBehaviorCoalescing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    onDarwinNotificationCallback(center, observer, name, object, userInfo, CFNotificationSuspensionBehaviorCoalesce);
}

static void onBehaviorHolding(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    onDarwinNotificationCallback(center, observer, name, object, userInfo, CFNotificationSuspensionBehaviorHold);
}

static void onBehaviorDeliverringImmediately(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    onDarwinNotificationCallback(center, observer, name, object, userInfo, CFNotificationSuspensionBehaviorDeliverImmediately);
}


static void onDarwinNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo, CFNotificationSuspensionBehavior behavior) {
    NSMutableDictionary *arguments = [@{@"name": (__bridge NSString *)name} mutableCopy];
    id obj = (__bridge id)object;
    if (obj && ([obj isKindOfClass:NSArray.class] ||
        [obj isKindOfClass:NSDictionary.class] ||
        [obj isKindOfClass:NSNumber.class] ||
        [obj isKindOfClass:FlutterStandardTypedData.class] ||
        [obj isKindOfClass:NSString.class])) {
        arguments[@"object"] = obj;
    }
    if (behavior != 0) arguments[@"behavior"] = @(behavior);
    if (userInfo) arguments[@"userInfo"] = (__bridge NSDictionary *)userInfo;
    
    [channel invokeMethod:FlutterDarwinNotficationReceiveNotification arguments:arguments.copy];
}

@end
