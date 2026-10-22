import Flutter
import MapKit
import MessageUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Buscador de destinos de New Trip (lib/features/trips/data/destination_repository.dart).
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TravioPlaces") else { return }
    FlutterMethodChannel(name: "travio/places", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "search",
          let query = (call.arguments as? [String: Any])?["query"] as? String
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        searchDestinations(query, result: result)
      }

    // Contact support (lib/features/you/data/mail_composer.dart).
    FlutterMethodChannel(name: "travio/mail", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "compose":
          guard let args = call.arguments as? [String: Any],
            let to = args["to"] as? String,
            let subject = args["subject"] as? String,
            let body = args["body"] as? String
          else {
            result(FlutterError(code: "bad_args", message: nil, details: nil))
            return
          }
          self?.composeMail(to: to, subject: subject, body: body, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private var mailResult: FlutterResult?

  /// Hoja de Mail dentro de la app; devuelve "sent", "saved", "cancelled", "failed" o "unavailable".
  private func composeMail(to: String, subject: String, body: String, result: @escaping FlutterResult) {
    guard MFMailComposeViewController.canSendMail(), let presenter = topViewController() else {
      result("unavailable")
      return
    }
    let composer = MFMailComposeViewController()
    composer.mailComposeDelegate = self
    composer.setToRecipients([to])
    composer.setSubject(subject)
    composer.setMessageBody(body, isHTML: false)
    mailResult = result
    presenter.present(composer, animated: true)
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
  func mailComposeController(
    _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?
  ) {
    let outcome: String
    switch result {
    case .sent: outcome = "sent"
    case .saved: outcome = "saved"
    case .cancelled: outcome = "cancelled"
    default: outcome = "failed"
    }
    controller.dismiss(animated: true)
    mailResult?(outcome)
    mailResult = nil
  }
}

/// Ciudades o países que coinciden con [query], con su país y moneda.
private func searchDestinations(_ query: String, result: @escaping FlutterResult) {
  let request = MKLocalSearch.Request()
  request.naturalLanguageQuery = query
  request.resultTypes = .address
  MKLocalSearch(request: request).start { response, error in
    if let error = error as? MKError, error.code == .placemarkNotFound {
      result([])
      return
    }
    if let error = error {
      result(FlutterError(code: "search_failed", message: error.localizedDescription, details: nil))
      return
    }
    var seen = Set<String>()
    var destinations: [[String: Any]] = []
    for item in response?.mapItems ?? [] {
      let placemark = item.placemark
      guard let country = placemark.country, let countryCode = placemark.isoCountryCode else { continue }
      let name = [placemark.locality, country].compactMap { $0 }.joined(separator: ", ")
      guard seen.insert(name).inserted else { continue }
      // La moneda depende de la región del locale (en_JP → JPY).
      let currency = (NSLocale(localeIdentifier: "en_\(countryCode)").object(forKey: .currencyCode) as? String)
      destinations.append(["name": name, "countryCode": countryCode, "currencyCode": currency ?? NSNull()])
    }
    result(destinations)
  }
}
