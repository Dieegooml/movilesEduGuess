import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore
import FacebookCore

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = 100 * 1024 * 1024 // 100 MB limit
        Firestore.firestore().settings = settings

        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        configureGIDSignIn()
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let handledByFB = ApplicationDelegate.shared.application(app, open: url, options: options)
        let handledByGoogle = GIDSignIn.sharedInstance.handle(url)
        return handledByFB || handledByGoogle
    }

    private func configureGIDSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let clientID = dict["CLIENT_ID"] as? String else {
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}
