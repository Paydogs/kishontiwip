@preconcurrency import ProjectDescription

// 1. The Main App Target
let defaultApp = Target.target(
    name: "KishontiAdmissionTask",
    destinations: [.iPhone],
    product: .app,
    bundleId: "com.magnificat.olahandrasadmission",
    deploymentTargets: .iOS("16.0"),
    infoPlist: .extendingDefault(
        with: [
            "UILaunchScreen": [
                "UIColorName": "",
                "UIImageName": "",
            ],
            "NSLocalNetworkUsageDescription": "PeerConnect uses your local network to discover nearby devices.",
            "NSBonjourServices": .array([
                "_peer-connect._tcp",
                "_peer-connect._udp"
            ]),
            "NSBluetoothAlwaysUsageDescription": "PeerConnect uses Bluetooth to maintain connections with nearby devices in the background.",
            "UIBackgroundModes": .array(["bluetooth-central", "bluetooth-peripheral"])
        ]
    ),
    sources: [
        .glob("Application/**/*.swift", excluding: ["Application/Tests/**"])
    ],
    resources: ["Application/Resources/**"],
//    entitlements: .dictionary([
//        "com.apple.developer.device-information.user-assigned-device-name": true
//    ]),
    dependencies: [
        .external(name: "FactoryKit"),
        .external(name: "Logging")
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "64GU57DP44",
            "CODE_SIGN_STYLE": "Automatic"
        ]
    )
)

// 2. The Unit Test Target (XCTest / Swift Testing)
let unitTests = Target.target(
    name: "KishontiAdmissionTaskTests",
    destinations: [.iPhone],
    product: .unitTests,
    bundleId: "com.magnificat.olahandrasadmissionTests",
    deploymentTargets: .iOS("16.0"),
    infoPlist: .default,
    sources: ["Application/Tests/UnitTests/**"],
    dependencies: [
        .target(name: "KishontiAdmissionTask") // Access app code via @testable import
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "64GU57DP44",
            "CODE_SIGN_STYLE": "Automatic"
        ]
    )
)

let project = Project(
    name: "KishontiAdmissionTask",
    targets: [defaultApp, unitTests],
    resourceSynthesizers: [
        .assets(),
        .strings(),
        .fonts()
    ]
)
