// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Decoy",
  products: [
    .library(
      name: "Decoy",
      targets: ["Decoy"]
    ),
  ],
  targets: [
    .target(
      name: "Decoy"
    ),
    .testTarget(
      name: "DecoyTests",
      dependencies: ["Decoy"],
      resources: [
        .process("Resources")
      ]
    ),
  ]
)
