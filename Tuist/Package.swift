
// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "FactoryKit": .framework,
            "Logging": .framework
        ],
        baseSettings: .settings(configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ])
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.5.3"),
        .package(url: "https://github.com/Apple/swift-log", from: "1.8.0")
    ],
    targets: [
    ]
)
