#import <JSDecoupledAppDelegate/JSDecoupledAppDelegate.h>


@interface ARAppNotificationsDelegate : NSObject <JSApplicationRemoteNotificationsDelegate>
- (void)registerForDeviceNotifications;
- (void)fetchNotificationCounts;
- (void)applicationDidReceiveRemoteNotification:(NSDictionary *)userInfo inApplicationState:(UIApplicationState)applicationState;
@end
