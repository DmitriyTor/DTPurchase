// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DTPurchase",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "DTPurchase", targets: ["DTPurchase"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DTPurchase", dependencies: [], path: "DTPurchase"),
        .testTarget(name: "DTPurchaseTests", dependencies: ["DTPurchase"]),
    ]
)
