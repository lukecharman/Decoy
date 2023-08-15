import Foundation

protocol RecorderInterface {
  var recordings: [[String: Any]] { get set }
  var shouldRecord: Bool { get }

  func record(url: URL, data: Data?, response: URLResponse?, error: Error?)
}

/// Used to record all API calls which come through the Decoy' `session`.
class Recorder: RecorderInterface {
  /// An array of each recorded response in the current app session.
  var recordings = [[String: Any]]()

  private let processInfo: ProcessInfo
  private let writer: WriterInterface

  init(processInfo: ProcessInfo = .processInfo, writer: WriterInterface = Writer()) {
    self.processInfo = processInfo
    self.writer = writer
  }

  /// Whether or not the app is running in the context of recording tests, as determined by
  /// the provided `ProcessInfo` object's launch environment..
  var shouldRecord: Bool {
    guard let modeString = processInfo.environment[Decoy.Constants.decoyMode] else {
      return false
    }

    guard let modeType = Decoy.TestMode(string: modeString) else {
      return false
    }

    return modeType.isRecording
  }

  func daysToLive() -> Int? {
    guard let modeString = processInfo.environment[Decoy.Constants.decoyMode] else {
      return nil
    }

    guard let modeType = Decoy.TestMode(string: modeString) else {
      return nil
    }

    switch modeType {
    case .recording(let int):
      return int == 0 ? nil : int
    default:
      return nil
    }
  }

  var expiresAt: String? {
    guard let daysToLive = daysToLive() else {
      return nil
    }

    if let futureDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: daysToLive, to: Date()) {
      return ISO8601DateFormatter().string(from: futureDate)
    } else {
      return nil
    }
  }

  /// Makes a recording of the provided data, response, and error to the specifed URL.
  ///
  /// - Parameters:
  ///   - url: The URL to which the call being stubbed was made.
  ///   - data: Optionally, the data returned from the call.
  ///   - response: Optionally, the URL response returned from the call.
  ///   - error: Optionally, the error returned from the call.
  func record(url: URL, data: Data?, response: URLResponse?, error: Error?) {
    let decoy = Stub(
      url: url,
      recordedAt: ISO8601DateFormatter().string(from: Date()),
      expiresAt: expiresAt,
      response: Stub.Response(
        data: data,
        urlResponse: response as? HTTPURLResponse,
        error: nil
      )
    )

    recordings.insert(decoy.asJSON, at: 0)

    try? writer.write(recordings: recordings)
  }
}
