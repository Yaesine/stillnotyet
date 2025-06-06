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
    // Initialize Firebase FIRST
    FirebaseApp.configure()
    print("Firebase initialized")

    // Set up UNUserNotificationCenter delegate IMMEDIATELY
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("UNUserNotificationCenter delegate set")
    }

    // Set messaging delegate
    Messaging.messaging().delegate = self
    print("Firebase Messaging delegate set")

    // Configure notification settings
    if #available(iOS 10.0, *) {
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("Notification permission granted: \(granted)")
          if let error = error {
            print("Notification permission error: \(error)")
          }

          // Register for remote notifications on main thread
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    // Configure Google Sign-In
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
      fatalError("GoogleService-Info.plist not found")
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)

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

    // Handle notification if app was launched from one
    if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
        print("App launched from notification: \(notification)")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleSignIn(controller: FlutterViewController, result: @escaping FlutterResult) {
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

  // CRITICAL: Show notifications when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    print("=== FOREGROUND NOTIFICATION RECEIVED ===")
    print("Title: \(notification.request.content.title)")
    print("Body: \(notification.request.content.body)")
    print("UserInfo: \(userInfo)")

    // Let FCM handle the message
    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Show notification banner even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // Handle notification taps
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("=== NOTIFICATION TAPPED ===")
    print("UserInfo: \(userInfo)")

    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler()
  }

  // Register APNS token
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("=== APNS TOKEN RECEIVED ===")
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("APNS token: \(token)")

    // CRITICAL: Set APNS token for FCM
    Messaging.messaging().apnsToken = deviceToken
    print("APNS token set for Firebase Messaging")

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle registration failure
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("=== FAILED TO REGISTER FOR REMOTE NOTIFICATIONS ===")
    print("Error: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Handle remote notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("=== REMOTE NOTIFICATION RECEIVED ===")
    print("UserInfo: \(userInfo)")

    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler(.newData)
  }

  // Handle URL schemes
  override func application(_ app: UIApplication,
                           open url: URL,
                           options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("=== FCM TOKEN RECEIVED ===")
    print("FCM Token: \(fcmToken ?? "nil")")

    if let token = fcmToken {
      // Send token to Flutter side via method channel if needed
      let dataDict: [String: String] = ["token": token]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
    }
  }
}
