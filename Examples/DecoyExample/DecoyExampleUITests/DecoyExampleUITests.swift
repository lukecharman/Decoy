import DecoyXCUI
import XCTest

final class DecoyExampleUITests: DecoyTestCase {
  override func setUp() {
    super.setUp(recording: true)
    app.launch()
  }

  func test_example_oneCallToOneEndpoint() {
    app.buttons["Fetch Apple"].firstMatch.tap()
    XCTAssert(app.staticTexts["Apple"].waitForExistence(timeout: 5))
  }

  func test_example_twoCallsToSameEndpoint() {
    app.buttons["Fetch Apple"].firstMatch.tap()
    XCTAssert(app.staticTexts["Apple"].waitForExistence(timeout: 5))
    app.buttons["Fetch Banana"].firstMatch.tap()
    XCTAssert(app.staticTexts["Banana"].waitForExistence(timeout: 5))
  }
}
