// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyQuixio",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "MyQuixio",
            targets: ["QuixioApp"],
            bundleIdentifier: "com.example.myquixio",
            teamIdentifier: "ABCDE12345",
            displayVersion: "1.0",
            bundleVersion: "1",
            iconAssetName: "AppIcon",
            accentColorAssetName: "AccentColor",
            supportedDeviceFamilies: [
                .phone, .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown,
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.25.0")
    ],
    targets: [
        .executableTarget(
            name: "QuixioApp",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)
