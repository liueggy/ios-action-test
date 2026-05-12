// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IOSActionTest",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "IOSActionTest",
            targets: ["IOSActionTest"]
        )
    ],
    targets: [
        .target(
            name: "IOSActionTest"
        ),
        .testTarget(
            name: "IOSActionTestTests",
            dependencies: ["IOSActionTest"]
        )
    ]
)
