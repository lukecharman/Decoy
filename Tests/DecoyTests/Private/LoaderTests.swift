import Foundation
import XCTest
@testable import Decoy

final class LoaderTests: XCTestCase {
  private var loader: Loader!

  override func setUp() {
    super.setUp()

    let processInfo = MockProcessInfo()
    processInfo.mockedIsRunningXCUI = true

    Decoy.setUp(processInfo: processInfo)
    loader = Loader()
  }

  override func tearDown() {
    loader = nil

    super.tearDown()
  }

  func test_loadJSON_shouldReturnNil_whenFileNotFoundInBundle() {
    XCTAssertNil(loader.loadJSON(from: URL(string: "file:///Nope")!))
  }

  func test_loadJSON_shouldReturnNil_whenURLContainsNonJSONData() {
    guard let url = Bundle.testing("BadJSONTest.json") else { return XCTFail(#function) }
    XCTAssertNil(loader.loadJSON(from: url))
  }

  func test_loadJSON_shouldReturnParsedData() {
    guard let url = Bundle.testing("LoaderTest.json") else { return XCTFail(#function) }
    let result = loader.loadJSON(from: url)
    XCTAssertEqual(result![0].identifier.stringValue, "https://testing-some-json")

    guard let expectedResult = try? JSONSerialization.data(withJSONObject: ["MOCKED OR WHATEVER"]) else {
      return XCTFail(#function)
    }

    XCTAssertEqual(result![0].response.data!, expectedResult)
  }

  func test_loadJSON_shouldNotParse_whenDictionaryHasNoURL() {
    guard let url = Bundle.testing("NoURLTest.json") else { return XCTFail(#function) }
    guard let result = loader.loadJSON(from: url) else { return XCTFail(#function) }
    XCTAssert(result.isEmpty)
  }

  func test_loadJSON_shouldNotParse_whenDictionaryHasURLWhichDoesNotParseIntoNSURL() {
    guard let url = Bundle.testing("BadURLTest.json") else { return XCTFail(#function) }
    guard let result = loader.loadJSON(from: url) else { return XCTFail(#function) }
    XCTAssert(result.isEmpty)
  }

  func test_loadJSON_shouldNotParse_whenDictionaryHasNoMock() {
    guard let url = Bundle.testing("NoMockTest.json") else { return XCTFail(#function) }
    guard let result = loader.loadJSON(from: url) else { return XCTFail(#function) }
    XCTAssert(result.isEmpty)
  }

  func test_loadJSON_shouldParse_whenDictionaryHasNoMockJSONInResponse() {
    guard let url = Bundle.testing("BadMockTest.json") else { return XCTFail(#function) }
    guard let result = loader.loadJSON(from: url) else { return XCTFail(#function) }
    XCTAssertNil(result[0].response.data)
  }

  func test_loadJSON_shouldReturnNilError() {
    guard let url = Bundle.testing("LoaderTest.json") else { return XCTFail(#function) }
    guard let result = loader.loadJSON(from: url) else { return XCTFail(#function) }
    XCTAssertNil(result[0].response.error)
  }
}
