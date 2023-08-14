import Foundation
import XCTest
@testable import Decoy

final class DecoyTests: XCTestCase {

  func test_json_shouldReturnNil_whenThereIsNoData() {
    let stubMark = Decoy(
      url: URL(string: "A")!,
      response: Decoy.Response(data: nil, urlResponse: nil, error: nil)
    )

    XCTAssertNil(stubMark.response.json)
  }

  func test_json_shouldReturnJSON_whenThereIsValidData() {
    let sourceJSON = ["A": "B"]
    let data = try? JSONSerialization.data(withJSONObject: sourceJSON)
    let response = Decoy.Response(data: data, urlResponse: nil, error: nil)
    XCTAssertEqual(response.json as? [String: String], sourceJSON)
  }

  func test_asJSON_shouldReturnMockWithContents_whenResponseHasData() {
    let sourceJSON = ["A": "B"]
    let data = try? JSONSerialization.data(withJSONObject: sourceJSON)
    let stubMark = Decoy(
      url: URL(string: "A")!,
      response: Decoy.Response(data: data, urlResponse: nil, error: nil)
    )

    let result = stubMark.asJSON
    let resultMock = result["stub"] as? [String: Any]
    XCTAssertEqual(resultMock?["json"] as? [String: String], sourceJSON)
  }

  func test_asJSON_shouldReturnMockWithResponseCode_whenResponseHasCode() {
    let url = URL(string: "A")!
    let response = HTTPURLResponse(url: url, statusCode: 456, httpVersion: nil, headerFields: nil)
    let stubMark = Decoy(
      url: url,
      response: Decoy.Response(data: nil, urlResponse: response, error: nil)
    )

    let result = stubMark.asJSON
    let resultMock = result["stub"] as? [String: Any]
    XCTAssertEqual(resultMock?["responseCode"] as? Int, 456)
  }

  func test_asJSON_shouldReturnMockWithError_whenResponseHasError() {
    let url = URL(string: "A")!
    let stubMark = Decoy(
      url: url,
      response: Decoy.Response(data: nil, urlResponse: nil, error: ["A": "B"])
    )

    let result = stubMark.asJSON
    let resultMock = result["stub"] as? [String: Any]
    XCTAssertEqual(resultMock?["error"] as? [String: String], ["A": "B"])
  }
}
