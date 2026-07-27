import Cocoa
import FirebaseAuth
import FirebaseCore
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Initialize Firebase from the bundled GoogleService-Info.plist so we can
    // configure Auth before Flutter's Dart code touches it.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    // Use the app's own private keychain space instead of a named access group.
    // This avoids the keychain-access-groups entitlement requirement that would
    // otherwise need a paid Apple Developer certificate to resolve.
    try? Auth.auth().useUserAccessGroup(nil)

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
