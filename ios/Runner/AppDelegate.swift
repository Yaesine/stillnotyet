import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    print("Setting up Firebase Messaging...")
    // Set messaging delegate BEFORE registering for notifications
    Messaging.messaging().delegate = self
    print("Firebase Messaging delegate set")

    // This is critical - set UNUserNotificationCenter delegate to self
    // to properly receive foreground notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Configure Google Sign-In
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
      fatalError("GoogleService-Info.plist not found")
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)

    // Set up notifications
    if #available(iOS 10.0, *) {
      // For iOS 10 and above
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("Notification permission granted: \(granted)")
          if let error = error {
            print("Notification permission error: \(error)")
          }

          // Important: Register for remote notifications AFTER permission is granted
          // This ensures the app has permission before requesting a token
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      )
    } else {
      // For iOS 9 and below
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    // Set up Flutter method channel for Google Sign-In
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let googleSignInChannel = FlutterMethodChannel(name: "com.yourapp/google_signin",
                                                  binaryMessenger: controller.binaryMessenger)

    googleSignInChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

      if call.method == "signIn" {
        self?.handleSignIn(controller: controller, result: result)
      } else if call.method == "signOut" {
        GIDSignIn.sharedInstance.signOut()
        result(nil)
      } else if call.method == "isSignedIn" {
        result(GIDSignIn.sharedInstance.hasPreviousSignIn())
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // Register flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // If this app was launched from a notification, handle it
    if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
        print("App launched from notification: \(notification)")
        // Process the notification data here
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleSignIn(controller: FlutterViewController, result: @escaping FlutterResult) {
    // Just proceed with sign in - Google SDK will automatically:
    // 1. Use Gmail/Google app if installed
    // 2. Fall back to browser if not installed

    GIDSignIn.sharedInstance.signIn(withPresenting: controller) { [weak self] signInResult, error in
      if let error = error {
        result(FlutterError(code: "SIGN_IN_FAILED",
                          message: error.localizedDescription,
                          details: nil))
        return
      }

      guard let user = signInResult?.user else {
        result(FlutterError(code: "SIGN_IN_FAILED",
                          message: "No user returned",
                          details: nil))
        return
      }

      // Get the ID token
      user.refreshTokensIfNeeded { _, error in
        if let error = error {
          result(FlutterError(code: "TOKEN_FAILED",
                            message: error.localizedDescription,
                            details: nil))
          return
        }

        let userData: [String: Any] = [
          "idToken": user.idToken?.tokenString ?? "",
          "accessToken": user.accessToken.tokenString,
          "email": user.profile?.email ?? "",
          "id": user.userID ?? "",
          "displayName": user.profile?.name ?? "",
          "photoUrl": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
        ]

        result(userData)
      }
    }
  }

  // Handle receiving notification when app is in foreground - this is critical
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    // Print message ID.
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID in foreground: \(messageID)")
    }

    // Print full message details for debugging
    print("Received foreground notification with data: \(userInfo)")

    // IMPORTANT: Change this to show notifications in foreground
    if #available(iOS 14.0, *) {
      // iOS 14+ supports banner presentation
      completionHandler([[.banner, .list, .sound, .badge]])
    } else {
      // For iOS 13 and below
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // Handle user tapping on the notification
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    // Print message ID.
    if let messageID = userInfo["gcm.message_id"] {
      print("User tapped notification with Message ID: \(messageID)")
    }

    // Print full message.
    print("Notification tap data: \(userInfo)")

    // Process the notification type
    if let type = userInfo["type"] as? String {
      print("Notification type: \(type)")
      // Here you could set up routing based on notification type
    }

    // Process notification data for FCM analytics
    Messaging.messaging().appDidReceiveMessage(userInfo)

    completionHandler()
  }

  // Register APNs token - Fixed duplicate code and added better logging
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("APNS token: \(token)")

    // Set the APNS token for Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    print("Set APNS token for Firebase Messaging")

    // Call super to ensure plugin functionality works correctly
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle registration errors - add this method
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Handle receiving remote notification (for both foreground and background)
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Received remote notification: \(userInfo)")

    // Process notification data for FCM analytics
    Messaging.messaging().appDidReceiveMessage(userInfo)

    completionHandler(.newData)
  }

  // Handle URL schemes (for Google Sign-In)
  override func application(_ app: UIApplication,
                           open url: URL,
                           options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Check if Google Sign-In can handle the URL
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }

    // Pass to Flutter plugins if Google Sign-In didn't handle it
    return super.application(app, open: url, options: options)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    // Save the token for your app - this helps with debugging
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )

    // You could send this token to your server from here
    if let token = fcmToken {
      // This is critical for debugging - log the full token
      print("FCM TOKEN: \(token)")
    }
  }
}