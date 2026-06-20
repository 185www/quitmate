import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Flutter local notifications (iOS 10+)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            // Request notification authorization upfront
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("QuitMate: Notification authorization error: \(error.localizedDescription)")
                }
                if granted {
                    print("QuitMate: Notification permission granted")
                } else {
                    print("QuitMate: Notification permission denied")
                }
            }
        }
        
        let controller = FlutterWindowManager()
        let window = UIWindow(frame: UIScreen.main.bounds)
        // FlutterViewController is created lazily by the engine; window setup follows.
        
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        if result {
            // Register for background fetch if needed (e.g., notification rescheduling)
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        
        return result
    }
    
    // MARK: - Handle notification response (iOS 10+)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Let Flutter handle the notification tap
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    // MARK: - Handle notification presentation (iOS 14+ foreground display)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when the app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // MARK: - Background fetch for notification rescheduling
    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Allow Flutter plugins to handle background fetch
        super.application(application, performFetchWithCompletionHandler: completionHandler)
    }
    
    // MARK: - Deep linking support
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Let Flutter handle deep links via uni_links or go_router
        return super.application(app, open: url, options: options)
    }
}
