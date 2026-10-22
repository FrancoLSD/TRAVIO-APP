import Flutter
import GoogleSignIn
import UIKit

/// Canal travio/google_sign_in: 'signIn' devuelve {idToken, accessToken} o nil si se cancela; 'signOut'.
/// El client ID sale de GIDClientID en Info.plist.
public class GoogleSignInNativePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "travio/google_sign_in", binaryMessenger: registrar.messenger())
    let instance = GoogleSignInNativePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "signIn":
      signIn(result)
    case "signOut":
      GIDSignIn.sharedInstance.signOut()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func signIn(_ result: @escaping FlutterResult) {
    guard let presenter = Self.topViewController() else {
      result(FlutterError(code: "no_view", message: "No view to present Google Sign-In", details: nil))
      return
    }
    GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { signInResult, error in
      if let error = error as NSError? {
        if error.domain == kGIDSignInErrorDomain && error.code == GIDSignInError.canceled.rawValue {
          result(nil)
        } else {
          result(FlutterError(code: "sign_in_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
        result(FlutterError(code: "sign_in_failed", message: "Google didn't return an ID token", details: nil))
        return
      }
      result(["idToken": idToken, "accessToken": user.accessToken.tokenString])
    }
  }

  // Vuelta desde Safari si el SDK no puede usar ASWebAuthenticationSession.
  public func application(
    _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
