import Foundation
import XCTest
@testable import Decoy

final class SessionTests: XCTestCase {

  private var stubURLSession: MockSession!
  private var stubMarksSession: Session!

  override func setUp() {
    super.setUp()
    stubURLSession = MockSession()
    Decoy.shared.recorder.recordings.removeAll()
    stubMarksSession = Session(stubbing: stubURLSession)
  }

  override func tearDown() {
    stubMarksSession = nil
    stubURLSession = nil
    super.tearDown()
  }

  private var urlRequest: URLRequest {
    URLRequest(url: url)
  }

  private var url: URL {
    URL(string: "https://api.com/endpoint")!
  }

  private var stringData: Data {
    "Test".data(using: .utf16)!
  }

  private var completion: (Data?, URLResponse?, Error?) -> Void {
    { _, _, _ in }
  }

  // MARK: - init

  func test_init_shouldStoreURLSession() {
    let sut = Session(stubbing: .shared)
    XCTAssertIdentical(sut.urlSession, URLSession.shared)
  }

  // MARK: - dataTaskWithURLRequest

  func test_dataTaskWithURLRequest_shouldReturnAppropriateSubclass() {
    let task = stubMarksSession.dataTask(with: urlRequest, completionHandler: completion)
    XCTAssert(task is DataTask)
  }

  func test_dataTaskWithURLRequest_shouldDeferCompletionHandlerToSuperclass() {
    _ = stubMarksSession.dataTask(with: urlRequest) { data, _, _ in
      XCTAssertEqual(data!, self.stringData)
    }
  }

  func test_dataTaskWithURLRequest_shouldNotRecordWhenRecordingIsDisabled() {
    _ = stubMarksSession.dataTask(with: url) { _, _, _ in }
    XCTAssert(stubURLSession.didCallDataTaskWithURL)
    XCTAssert(Decoy.shared.recorder.recordings.isEmpty)
  }

  func test_dataTaskWithURLRequest_shouldRecordWhenRecordingIsEnabled() {
    let stubRecorder = MockRecorder()
    stubRecorder.stubbedShouldRecord = true

    stubMarksSession.recorder = stubRecorder
    _ = stubMarksSession.dataTask(with: urlRequest) { _, _, _ in }
    XCTAssert(stubRecorder.didCallRecord)
  }

  // MARK: - dataTaskWithURL

  func test_dataTaskWithURL_shouldDeferResponseFromSuperclass() {
    _ = stubMarksSession.dataTask(with: url) { _, _, _ in }
    XCTAssert(stubURLSession.didCallDataTaskWithURL)
  }

  func test_dataTaskWithURL_shouldDeferCompletionHandlerToSuperclass() {
    _ = stubMarksSession.dataTask(with: url) { data, _, _ in
      XCTAssertEqual(data!, self.stringData)
    }
  }

  func test_dataTaskWithURL_shouldRecordWhenRecordingIsEnabled() {
    let stubRecorder = MockRecorder()
    stubRecorder.stubbedShouldRecord = true

    stubMarksSession.recorder = stubRecorder
    _ = stubMarksSession.dataTask(with: url) { _, _, _ in }
    XCTAssert(stubRecorder.didCallRecord)
  }
}

private class MockSession: URLSession {
  var didCallDataTaskWithURLRequest = false
  var didCallDataTaskWithURL = false

  override func dataTask(
    with request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask {
    didCallDataTaskWithURLRequest = true
    let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
    return MockDataTask(stubbing: task, completionHandler: completionHandler)
  }

  override func dataTask(
    with url: URL,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask {
    didCallDataTaskWithURL = true
    let task = URLSession.shared.dataTask(with: url, completionHandler: completionHandler)
    return MockDataTask(stubbing: task, completionHandler: completionHandler)
  }
}

private class MockDataTask: DataTask {
  override init(stubbing task: URLSessionDataTask, completionHandler: @escaping DataTask.CompletionHandler) {
    super.init(stubbing: task, completionHandler: completionHandler)
    completionHandler(("Test".data(using: .utf16)!, nil, nil))
  }
}

private class MockRecorder: RecorderInterface {
  var recordings: [[String: Any]] = [[:]]

  var stubbedShouldRecord = false

  var shouldRecord: Bool {
    stubbedShouldRecord
  }

  var didCallRecord = false

  func record(url: URL, data: Data?, response: URLResponse?, error: Error?) {
    didCallRecord = true
  }
}
