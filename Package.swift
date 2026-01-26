// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "pfw",
  platforms: [
    .macOS(.v15)
  ],
  products: [
        .executable(
            name: "pfw",
            targets: ["pfw"]
        ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.20"),
  ],
  targets: [
    .executableTarget(
      name: "pfw",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
