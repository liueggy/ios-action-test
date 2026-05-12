// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EggTool",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "EggTool", targets: ["EggTool"])
    ],
    targets: [
        .executableTarget(
            name: "EggTool",
            path: "App",
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("EventKit"),
                .linkedFramework("PhotosUI"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreImage"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("Network"),
                .linkedFramework("QuickLook"),
                .linkedFramework("Combine")
            ]
        )
    ]
)
