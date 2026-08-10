// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StorySlides",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "StorySlides", targets: ["StorySlides"])
    ],
    targets: [
        .target(name: "StorySlides")
    ]
)
