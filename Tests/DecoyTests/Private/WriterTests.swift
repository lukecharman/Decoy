import Foundation
import XCTest
@testable import Decoy
import DecoyTestHelpers

final class WriterTests: XCTestCase {
  func test_append_shouldThrowFilePathNotFound_whenPathIsMissing() {
    let processInfo = MockProcessInfo()
    processInfo.mockedEnvironment = [
      Decoy.Constants.mockFilename: "A"
    ]

    XCTAssertThrowsError(try Writer(processInfo: processInfo, logger: Logger()).append(recording: [:])) { error in
      XCTAssertEqual(error as? WriterError, .filePathNotFound)
    }
  }

  func test_append_shouldThrowFilePathNotFound_whenFileIsMissing() {
    let processInfo = MockProcessInfo()
    processInfo.mockedEnvironment = [
      Decoy.Constants.mockDirectory: "A"
    ]

    XCTAssertThrowsError(try Writer(processInfo: processInfo, logger: Logger()).append(recording: [:])) { error in
      XCTAssertEqual(error as? WriterError, .filePathNotFound)
    }
  }

  func test_append_shouldThrowFilePathNotFound_whenBothPathAndFileAreMissing() {
    let processInfo = MockProcessInfo()
    processInfo.mockedEnvironment = [:]

    XCTAssertThrowsError(try Writer(processInfo: processInfo, logger: Logger()).append(recording: [:])) { error in
      XCTAssertEqual(error as? WriterError, .filePathNotFound)
    }
  }

  func test_append_shouldAskFileManagerToCreateDirectory() {
    let fileManager = MockFileManager()

    let processInfo = MockProcessInfo()
    processInfo.mockedEnvironment = [
      Decoy.Constants.mockDirectory: "A",
      Decoy.Constants.mockFilename: "B"
    ]

    try? Writer(processInfo: processInfo, fileManager: fileManager, logger: Logger()).append(recording: [:])

    XCTAssert(fileManager.didCallCreateDirectory)
  }
}
