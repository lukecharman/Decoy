import Foundation
import XCTest
@testable import Decoy

final class DataTaskTests: XCTestCase {

  var stubbedProcessInfo: MockProcessInfo!

  override func setUp() {
    super.setUp()
    stubbedProcessInfo = MockProcessInfo()
  }

  override func tearDown() {
    stubbedProcessInfo = nil
    super.tearDown()
  }

  func test_init_shouldStoreTask() {
    let task = URLSessionDataTask()
    let stubMarksTask = DataTask(stubbing: task) { _, _, _ in }
    XCTAssertIdentical(task, stubMarksTask.task)
  }

  func test_overriddenResume_shouldCallInternalResume() {
    let task = MockURLSessionDataTask()
    let stubMarksTask = DataTask(stubbing: task) { _, _, _ in }
    stubMarksTask.resume()
    XCTAssert(task.didCallResume)
  }

  func test_resume_shouldDeferToSuperclass_whenTaskHasNoURL() {
    stubbedProcessInfo.stubbedIsRunningXCUI = true

    let task = MockURLSessionDataTask()
    let stubMarksTask = DataTask(stubbing: task) { _, _, _ in }
    stubMarksTask.resume(processInfo: stubbedProcessInfo)
    XCTAssert(task.didCallResume)
  }

  func test_resume_shouldDeferToSuperclass_whenNotRunningXCUI() {
    stubbedProcessInfo.stubbedIsRunningXCUI = false

    let task = MockURLSessionDataTask()
    let stubMarksTask = DataTask(stubbing: task) { _, _, _ in }
    stubMarksTask.resume(processInfo: stubbedProcessInfo)
    XCTAssert(task.didCallResume)
  }

  func test_resume_shouldDeferToSuperclass_whenNoQueuedResponseIsAvailable() {
    stubbedProcessInfo.stubbedIsRunningXCUI = true

    let task = MockURLSessionDataTask()
    task.stubbedCurrentRequest = URLRequest(url: URL(string: "http://no-stubs.for.me")!)

    let stubMarksTask = DataTask(stubbing: task) { _, _, _ in }
    stubMarksTask.resume(processInfo: stubbedProcessInfo)
    XCTAssert(task.didCallResume)
  }

  func test_resume_shouldReturnNextMockedResponse_whenAvailable() {
    stubbedProcessInfo.stubbedIsRunningXCUI = true

    let url = URL(string: "A")!
    guard let data = try? JSONSerialization.data(withJSONObject: ["A": "B"]) else { return XCTFail(#function) }
    let response = Stub.Response(data: data, urlResponse: nil, error: nil)
    Decoy.shared.queue.queue(
      stub: Stub(url: URL(string: "A")!, recordedAt: "2023-08-15T11:37:08+0000", response: response)
    )

    let task = MockURLSessionDataTask()
    task.stubbedCurrentRequest = URLRequest(url: url)

    DataTask(stubbing: task) { data, _, _ in
      guard let data = data else {
        return XCTFail(#function)
      }

      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return XCTFail(#function)
      }

      XCTAssertEqual(json["A"] as? String, "B")
    }.resume(processInfo: stubbedProcessInfo)

    XCTAssertFalse(task.didCallResume)
  }
}

private class MockURLSessionDataTask: URLSessionDataTask {

  var didCallResume = false
  var stubbedCurrentRequest: URLRequest?

  override func resume() {
    didCallResume = true
  }

  override var currentRequest: URLRequest? {
    stubbedCurrentRequest
  }
}
