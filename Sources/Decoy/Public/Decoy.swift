import Foundation

/// The `Decoy` class is the core of the library, and allows you to queue stubbed responses
/// to calls to specific endpoints via the `queue` and `queueValidResponse` methods.
public class Decoy {
  /// Constants used to communicate between the XCUI target and the app target via environment variables.
  public struct Constants {
    public static let isXCUI = "DECOY_IS_XCUI"
    public static let decoyMode = "DECOY_MODE"
    public static let decoyPath = "DECOY_PATH"
    public static let decoyFilename = "DECOY_FILENAME"
    public static let decoysFolder = "__Decoys__"
  }

  /// Enum listing modes in which tests can be run.
  public enum TestMode: Equatable {
    /// Stubs will be captured and recorded. Tests will always fail in this mode.
    /// The associated value
    case recording(Int)
    /// Stubs will be used where provided, and live calls made where not provided.
    case stubbing
    /// Stubs will be ignored, and live network requests will be made throughout.
    case live

    /// Initialise a TestMode with its string representation from a launch environment variable.
    ///
    /// - Parameters:
    ///   - string: A `String` representation of a `TestMode` written in `DecoyXCUI`.
    init?(string: String) {
      if string.hasPrefix("recording"), let last = string.split(separator: "_").last, let int = Int(last) {
        self = .recording(int)
      } else if string == "live" {
        self = .live
      } else if string == "stubbing" {
        self = .stubbing
      } else {
        return nil
      }
    }

    public var stringValue: String {
      switch self {
      case .recording(let int):
        return "recording_\(int)"
      case .stubbing:
        return "stubbing"
      case .live:
        return "live"
      }
    }

    public static func == (lhs: TestMode, rhs: TestMode) -> Bool {
      switch (lhs, rhs) {
      case (.recording(let int1), .recording(let int2)):
        return int1 == int2
      case (.stubbing, .stubbing), (.live, .live):
        return true
      default:
        return false
      }
    }

    public var isRecording: Bool {
      switch self {
      case .recording(_):
        return true
      default:
        return false
      }
    }
  }

  /// Singleton used to access Decoy from the outside without the need to instantiate it.
  public static let shared = Decoy()

  /// Performs initial setup for Decoy. Should be called as soon as possible after your app launches
  /// so that calls made immediately following app launch can be stubbed, if required. Early exits
  /// immediately if not in the context of UI testing to avoid unnecessary processing.
  ///
  /// - Parameters:
  ///   - processInfo: An injectable instance of `ProcessInfo` used to check environment variables.
  public func setUp(session: SessionInterface, processInfo: ProcessInfo = .processInfo) {
    self.session = session

    guard isXCUI(processInfo: processInfo) else { return }
    guard let directory = processInfo.environment[Decoy.Constants.decoyPath] else { return }
    guard let filename = processInfo.environment[Decoy.Constants.decoyFilename] else { return }

    var url = URL(safePath: directory)
    url.safeAppend(path: filename)

    guard let json = loader.loadJSON(from: url) else { return }

    json.forEach {
      queue.queue(stub: Stub(url: $0.url, recordedAt: $0.recordedAt, expiresAt: $0.expiresAt, response: $0.response))
    }
  }

  /// Used to ascertain whether or not Decoy is currently running within the context of a `DecoyUITestCase`.
  public func isXCUI(processInfo: ProcessInfo = .processInfo) -> Bool {
    processInfo.environment[Constants.isXCUI] == String(true)
  }

  /// A `URLSession` set to this variable will have its scheduled data tasks checked for suitable stubs.
  public var session: SessionInterface?

  /// Used to ascertain the testing mode in which Decoy is running.
  /// Defaults to `.stubbing` if not found.
  func mode(processInfo: ProcessInfo = .processInfo) -> Decoy.TestMode {
    guard let modeString = processInfo.environment[Constants.decoyMode] else {
      return .stubbing
    }

    return Decoy.TestMode(string: modeString) ?? .stubbing
  }

  /// A queue, handling the management of responses into and out of the response queue.
  var queue: QueueInterface = Queue()

  /// A loader, used to read data from a JSON stub file and parse it into a stubbed response.
  var loader: LoaderInterface = Loader()

  /// A recorder, used to write recorded stubs out to disk.
  var recorder: RecorderInterface = Recorder()

  /// Dispatches the next queued response for the provided URL. Checks the queued response array for responses
  /// matching the given URL, and returns and removes the most recently added.
  ///
  /// - Parameters:
  ///   - url: The url for which the next queued `response` will return.
  ///   - completion: A closure to be called with the queued response.
  func dispatchNextQueuedResponse(for url: URL, to completion: @escaping DataTask.CompletionHandler) -> Bool {
    queue.dispatchNextQueuedResponse(for: url, to: completion)
  }
}
