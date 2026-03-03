// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GLM_Usage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GLM_Usage", targets: ["GLM_Usage"])
    ],
    targets: [
        .executableTarget(
            name: "GLM_Usage",
            path: "Sources"
        )
    ]
)
