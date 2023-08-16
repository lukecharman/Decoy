import Foundation

/// A data structure representing a stubbed response to a specific URL.
public struct Stub {
  /// The URL to which queries will return the associated stub.
  public let url: URL
  /// A timestamp for when this stub was recorded.
  public let recordedAt: String
  /// An optional timestamp after which the stub should be considered invalid or expired.
  public let expiresAt: String?
  /// The stubbed response which will be returned to the `Response`'s `url`.
  public let response: Response

  /// Packages the different parts of a stubbed response.
  public struct Response {
    /// The data returned.
    public let data: Data?
    /// The HTTP URL response of the stub.
    public let urlResponse: HTTPURLResponse?
    /// A dictionary containing error information that the stub can return if present.
    public let error: [String: Any]?
    /// The data converted to JSON.
    public var json: Any? {
      guard let data else { return nil }
      return try? JSONSerialization.jsonObject(with: data)
    }
  }

  public var hasExpired: Bool {
    guard let expiresAt else {
      return false
    }

    guard let date = ISO8601DateFormatter().date(from: expiresAt) else {
      return false
    }

    return date > Date()
  }

  /// Returns the Decoy encoded as a JSON dictionary.
  var asJSON: [String: Any] {
    var json = [String: Any]()

    json["url"] = url.absoluteString
    json["recordedAt"] = recordedAt

    if let expiresAt {
      json["expiresAt"] = expiresAt
    }

    var stub = [String: Any]()

    if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data) {
      stub["json"] = json
    }

    if let code = response.urlResponse?.statusCode {
      stub["responseCode"] = code
    }

    if let error = response.error {
      stub["error"] = error
    }

    json["stub"] = stub

    return json
  }
}
