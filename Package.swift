// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "pfw-cli",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .executableTarget(
      name: "pfw",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
