// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlassTasks",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "GlassTasks", targets: ["GlassTasks"])
    ],
    targets: [
        .executableTarget(
            name: "GlassTasks",
            path: "App",
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("EventKit"),
                .linkedFramework("Combine")
            ]
        )
    ]
)
