// swift-tools-version: 5.9
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
