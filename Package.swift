// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Stencil",
  products: [
    .library(name: "Stencil", targets: ["Stencil"])
  ],
  targets: [
    .target(name: "Stencil", path: "Sources")
  ]
)
