@testable import Decoy
import XCTest

class DecoyURLProtocolTests: XCTestCase {
  let decoyModeKey = Decoy.Constants.mode

  override func setUp() {
    super.setUp()

    let mockProcessInfo = MockProcessInfo()
    mockProcessInfo.mockedEnvironment?[Decoy.Constants.mode] = "record"

    Decoy.setUp(processInfo: mockProcessInfo)
    Decoy.recorder = MockRecorder()

    URLSessionConfiguration.default.protocolClasses = [MockLiveURLProtocol.self, DecoyURLProtocol.self]
    URLProtocol.registerClass(MockLiveURLProtocol.self)
  }

  override func tearDown() {
    URLProtocol.unregisterClass(MockLiveURLProtocol.self)
    super.tearDown()
  }

  func test_canInitAndCanonicalRequest() {
    let request = URLRequest(url: URL(string: "https://example.com")!)
    XCTAssert(DecoyURLProtocol.canInit(with: request))
    let canonical = DecoyURLProtocol.canonicalRequest(for: request)
    XCTAssertEqual(canonical, request)
  }

  func test_nilURL() {
    var request = URLRequest(url: URL(string: "https://example.com")!)
    request.url = nil
    let client = FakeURLProtocolClient()
    let protocolInstance = DecoyURLProtocol(request: request, cachedResponse: nil, client: client)

    protocolInstance.startLoading()

    XCTAssertNotNil(client.receivedError)
    if let error = client.receivedError as? URLError {
      XCTAssertEqual(error.code, .badURL)
    }
  }

  func test_handleMockResponse() {
    let url = URL(string: "https://example.com/mock")!
    let expectedData = "mock data".data(using: .utf8)
    let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
    let stubResponse = Stub.Response(data: expectedData, urlResponse: expectedResponse, error: nil)

    Decoy.queue.queuedResponses[.url(url)] = [stubResponse]

    let testRecorder = Decoy.recorder as! MockRecorder
    testRecorder.mockedShouldRecord = true

    let request = URLRequest(url: url)
    let client = FakeURLProtocolClient()
    let protocolInstance = DecoyURLProtocol(request: request, cachedResponse: nil, client: client)

    protocolInstance.startLoading()

    XCTAssertEqual(client.loadedData, expectedData)
    XCTAssertNotNil(client.receivedResponse)

    if let httpResponse = client.receivedResponse as? HTTPURLResponse {
      XCTAssertEqual(httpResponse.statusCode, 200)
    }
    XCTAssert(client.finishLoadingCalled)

    XCTAssertEqual(testRecorder.recordCallCount, 1)
  }

  func test_sendForceOfflineError() {
    let url = URL(string: "https://example.com/offline")!
    let request = URLRequest(url: url)

    let mockProcessInfo = MockProcessInfo()
    mockProcessInfo.mockedEnvironment?[Decoy.Constants.mode] = "forceOffline"

    Decoy.setUp(processInfo: mockProcessInfo)
    Decoy.queue.queuedResponses[.url(url)] = nil

    let client = FakeURLProtocolClient()
    let protocolInstance = DecoyURLProtocol(request: request, cachedResponse: nil, client: client)

    protocolInstance.startLoading()

    XCTAssertNotNil(client.receivedError)
    if let nsError = client.receivedError as NSError? {
      XCTAssertEqual(nsError.domain, "DecoyErrorDomain")
      XCTAssertEqual(nsError.code, -1)
      XCTAssert(nsError.localizedDescription.contains("No mock available for URL"))
    }
  }
}
