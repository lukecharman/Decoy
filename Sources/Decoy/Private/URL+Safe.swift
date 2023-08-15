import Foundation

/// Extension for the URL class to provide safer path operations tailored for different iOS versions.
extension URL {
  /// Initializes a URL based on the file path, considering iOS version specifics.
  /// - Parameter path: The file path.
  init(safePath path: String) {
    if #available(iOS 16, *) {
      self.init(filePath: path)
    } else {
      self.init(fileURLWithPath: path)
    }
  }

  /// Appends a path component to the URL, considering iOS version specifics.
  /// - Parameter path: The path component to append.
  mutating func safeAppend(path: String) {
    if #available(iOS 16, *) {
      self.append(path: path)
    } else {
      self.appendPathComponent(path)
    }
  }
}
