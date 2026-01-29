// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "pfw",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "pfw", targets: ["pfw"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-nio", from: "2.60.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.9"),
    .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.20"),
  ],
  targets: [
    .executableTarget(
      name: "pfw",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
      ],
      resources: [
        .process("Resources")
      ],
      swiftSettings: [
        .enableUpcomingFeature("NonisolatedNonsendingByDefault")
      ]
    ),
    .testTarget(
      name: "pfwTests",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        "pfw",
      ],
      swiftSettings: [
        .enableUpcomingFeature("NonisolatedNonsendingByDefault")
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
