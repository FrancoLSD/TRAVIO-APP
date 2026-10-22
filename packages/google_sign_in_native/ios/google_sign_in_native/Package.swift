// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "google_sign_in_native",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "google-sign-in-native", targets: ["google_sign_in_native"])
  ],
  dependencies: [
    // Commit «Add SPM AppCheckCore 12.x support» (15 oct 2026): la 10.0.0 publicada aún pide
    // app-check 11 y Firebase 13 usa la 12. Pasar a `from:` con la primera versión que lo incluya.
    .package(url: "https://github.com/google/GoogleSignIn-iOS", revision: "4ce331c226c24cfee688b31e9c3731cc5c5e2862")
  ],
  targets: [
    .target(
      name: "google_sign_in_native",
      dependencies: [
        .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
      ]
    )
  ]
)
