import Foundation
import XCTest
@testable import Decoy

final class DecoyTests: XCTestCase {

  override func setUp() {
    super.setUp()
    Decoy.shared.queue.queuedResponses.removeAll()
  }

  func test_isXCUI_shouldReferToProcessInfo_whenTrue() {
    let stubbedProcessInfo = MockProcessInfo()
    stubbedProcessInfo.stubbedIsRunningXCUI = true
    XCTAssert(Decoy.shared.isXCUI(processInfo: stubbedProcessInfo))
  }

  func test_isXCUI_shouldReferToProcessInfo_whenFalse() {
    let stubbedProcessInfo = MockProcessInfo()
    stubbedProcessInfo.stubbedIsRunningXCUI = false
    XCTAssertFalse(Decoy.shared.isXCUI(processInfo: stubbedProcessInfo))
  }

  func test_setUp_shouldNotLoadJSON_whenXCUIIsNotRunning() {
    let processInfo = MockProcessInfo()
    processInfo.stubbedIsRunningXCUI = false
    Decoy.shared.setUp(session: Session(), processInfo: processInfo)
    XCTAssert(Decoy.shared.queue.queuedResponses.isEmpty)
  }

  func test_setUp_shouldNotLoadJSON_whenMockDirectoryIsNotSet() {
    let processInfo = MockProcessInfo()
    processInfo.stubbedEnvironment = [
      Decoy.Constants.isXCUI: String(true),
      Decoy.Constants.decoyFilename: "B"
    ]
    Decoy.shared.setUp(session: Session(), processInfo: processInfo)
    XCTAssert(Decoy.shared.queue.queuedResponses.isEmpty)
  }

  func test_setUp_shouldNotQueue_whenMockFilenameIsNotSet() {
    let processInfo = MockProcessInfo()
    processInfo.stubbedEnvironment = [
      Decoy.Constants.isXCUI: String(true),
      Decoy.Constants.decoyPath: "B"
    ]
    Decoy.shared.setUp(session: Session(), processInfo: processInfo)
    XCTAssert(Decoy.shared.queue.queuedResponses.isEmpty)
  }

  func test_setUp_shouldLoadJSON_whenURLDoesContainJSON() {
    let url = Bundle.module.url(forResource: "LoaderTests", withExtension: "json")
    let dir = url?.deletingLastPathComponent()

    let processInfo = MockProcessInfo()
    processInfo.stubbedEnvironment = [
      Decoy.Constants.isXCUI: String(true),
      Decoy.Constants.decoyPath: dir!.absoluteString,
      Decoy.Constants.decoyFilename: "LoaderTests.json"
    ]

    Decoy.shared.setUp(session: Session(), processInfo: processInfo)
    XCTAssertFalse(Decoy.shared.queue.queuedResponses.isEmpty)
  }

  func test_dispatchNextQueuedResponse_shouldCallCompletion() {
    guard let data = try? JSONSerialization.data(withJSONObject: ["A": "B"]) else { return XCTFail(#function) }
    let response = Decoy.Response(data: data, urlResponse: nil, error: nil)
    let decoy = Decoy(url: url, response: response)

    Decoy.shared.queue.queue(decoy: decoy)
    _ = Decoy.shared.dispatchNextQueuedResponse(for: url) { data, _, _ in
      guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
        return XCTFail(#function)
      }

      guard let result = json["A"] as? String else { return XCTFail(#function) }

      XCTAssertEqual(result, "B")
    }
  }
}

private extension DecoyTests {

  var url: URL {
    URL(string: "A")!
  }
}
