import Foundation

/// Protocol that defines the interface for writing recordings.
protocol WriterInterface {
  /// Writes an array of recordings to a file.
  ///
  /// - Parameter recordings: An array of dictionaries representing recordings.
  /// - Throws: `WriterError` if there's an issue with the file path or serialization.
  func write(recordings: [[String: Any]]) throws
}

/// Custom errors that might occur during writing.
enum WriterError: Error {
  case filePathNotFound
  case couldNotSerializeJSON
}

/// A class that implements the `WriterInterface` protocol for writing recordings to a file.
class Writer: WriterInterface {
  private let processInfo: ProcessInfo
  private let fileManager: FileManager

  /// Initializes a new `Writer` instance.
  /// - Parameters:
  ///   - processInfo: The `ProcessInfo` object. Default is `.processInfo`.
  ///   - fileManager: The `FileManager` object. Default is `.default`.
  init(processInfo: ProcessInfo = .processInfo, fileManager: FileManager = .default) {
    self.processInfo = processInfo
    self.fileManager = fileManager
  }

  /// Writes an array of recordings to a file.
  ///
  /// - Parameter recordings: An array of dictionaries representing recordings.
  /// - Throws: `WriterError` if there's an issue with the file path or serialization.
  func write(recordings: [[String: Any]]) throws {
    /// Retrieve the path and file name from environment variables.
    guard let path = path, let file = file else { throw WriterError.filePathNotFound }

    /// Serialize the recordings data into JSON format.
    guard let data = try? JSONSerialization.data(withJSONObject: recordings, options: .prettyPrinted) else {
      throw WriterError.couldNotSerializeJSON
    }

    /// Create a URL for the directory using the given path.
    var url = URL(safePath: path)

    /// Create the directory and intermediate directories if they don't exist.
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

    /// Append the file name to the URL.
    url.safeAppend(path: file)

    /// Write the serialized JSON data to the specified URL.
    try data.write(to: url)
  }
}

private extension Writer {
  /// Retrieves the path from environment variables.
  var path: String? {
    processInfo.environment[Decoy.Constants.decoyPath]
  }

  /// Retrieves the file name from environment variables.
  var file: String? {
    processInfo.environment[Decoy.Constants.decoyFilename]
  }
}
