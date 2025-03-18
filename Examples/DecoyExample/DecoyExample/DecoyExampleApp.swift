import Decoy
import SwiftUI

@main
struct DecoyExampleApp: App {
  @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView(api: api)
    }
  }

  /// If we're in an XCUI environment and Decoy has been set up with a session, use it in our `APIClient` so that calls
  /// to it will be intercepted. If we're not XCUI or there's no Decoy setup (i.e. in your app when not attached to XCUI),
  /// use your normal `URLSession`, in this instance the default `.shared` instance.
  var api: APIClient {
    if Decoy.isXCUI(), let urlSession = Decoy.urlSession {
      return APIClient(session: urlSession)
    } else {
      return APIClient(session: .shared)
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    /// As early as possible in your app launch process, call `Decoy.setUp()`, optionally passing in a `URLSession` instance.
    /// This will set up Decoy to begin intercepting traffic to that session. If you don't provide a session, the default
    /// `URLSession.shared` will be used.
    Decoy.setUp(session: .shared)
    return true
  }
}
