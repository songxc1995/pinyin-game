// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PinyinKitchen",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "PinyinKitchen", targets: ["PinyinKitchen"])
    ],
    targets: [
        .executableTarget(
            name: "PinyinKitchen",
            path: "Sources"
        )
    ]
)
