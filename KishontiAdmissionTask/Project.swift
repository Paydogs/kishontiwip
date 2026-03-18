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
        ]
    ),
    sources: [
        .glob("Application/**/*.swift", excluding: ["Application/Tests/**"])
    ],
    resources: ["Application/Resources/**"],
    dependencies: [
        .external(name: "Alamofire"),
        .external(name: "Lottie"),
        .external(name: "Toolkit"),
        .external(name: "Swinject"),
        .external(name: "Logging")
    ]
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
    ]
)

// 3. The UI Test Target
let uiTests = Target.target(
    name: "KishontiAdmissionTaskUITests",
    destinations: [.iPhone],
    product: .uiTests,
    bundleId: "com.magnificat.olahandrasadmissionUITests",
    deploymentTargets: .iOS("16.0"),
    infoPlist: .default,
    sources: ["Application/Tests/UITests/**"],
    dependencies: [
        .target(name: "KishontiAdmissionTask")
    ]
)

let project = Project(
    name: "KishontiAdmissionTask",
    targets: [defaultApp, unitTests, uiTests],
    resourceSynthesizers: [
        .assets(),
        .strings(),
        .fonts()
    ]
)