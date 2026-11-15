// swift-tools-version:5.9
import PackageDescription

// Pure-Swift game logic. No UIKit/SwiftUI: builds and tests on macOS CI and Linux.
let package = Package(
    name: "FingerPickerCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FingerPickerCore", targets: ["FingerPickerCore"])],
    targets: [
        .target(name: "FingerPickerCore"),
        .testTarget(name: "FingerPickerCoreTests", dependencies: ["FingerPickerCore"]),
    ]
)
