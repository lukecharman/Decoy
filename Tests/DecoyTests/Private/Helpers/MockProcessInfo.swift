import Foundation
import Decoy

class MockProcessInfo: ProcessInfo {
  var stubbedIsRunningXCUI = false
  var stubbedEnvironment: [String: String]?

  override var environment: [String: String] {
    if let stubbedEnvironment {
      return stubbedEnvironment
    } else {
      return [
        DecoyHub.Constants.stubDirectory: "DecoyTests",
        DecoyHub.Constants.isXCUI: String(stubbedIsRunningXCUI)
      ]
    }
  }
}
