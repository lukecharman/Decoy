import Foundation

protocol LoaderInterface {
  func loadJSON(from url: URL) -> [Stub]?
}

/// Simple typealiases used to make this structure cleaner to read.
private typealias DecoyDictionary = [String: Any]
private typealias DecoyArray = [DecoyDictionary]

/// Used to load stubs from JSON files, and decode them.
struct Loader: LoaderInterface {
  
  struct Constants {
    static let url = "url"
    static let stub = "stub"
    static let json = "json"
    static let error = "error"
    static let statusCode = "statusCode"
    static let httpVersion = "httpVersion"
    static let headerFields = "headerFields"
    static let recordedAt = "recordedAt"
  }
  
  /// Looks for a JSON file at the given URL, and decodes its contents into an array of stubbed responses.
  ///
  /// - Parameters:
  ///   - url: The location at which to look for a JSON file containing ordered, stubbed responses.
  ///
  /// - Returns: An optional array of `Decoy`s, read sequentially from the named JSON.
  func loadJSON(from url: URL) -> [Stub]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let json = try? JSONSerialization.jsonObject(with: data) as? DecoyArray else { return nil }
    
    return json.compactMap { stub(from: $0) }
  }
}

private extension Loader {
  func stub(from json: [String: Any]) -> Stub? {
    guard let urlString = json[Constants.url] as? String else { return nil }
    guard let url = URL(string: urlString) else { return nil }
    guard let stub = json[Constants.stub] as? DecoyDictionary else { return nil }
    guard let recordedAt = recordedAt(from: json) else { return nil }

    let data = data(from: stub)
    let urlResponse = urlResponse(to: url, from: stub)
    let response = Stub.Response(data: data, urlResponse: urlResponse, error: nil)

    return Stub(url: url, recordedAt: recordedAt, response: response)
  }

  func data(from stub: DecoyDictionary) -> Data? {
    guard let json = stub[Constants.json] else { return nil }
    return try? JSONSerialization.data(withJSONObject: json)
  }

  func urlResponse(to url: URL, from stub: DecoyDictionary) -> HTTPURLResponse? {
    HTTPURLResponse(
      url: url,
      statusCode: stub[Constants.statusCode] as? Int ?? 200,
      httpVersion: stub[Constants.httpVersion] as? String,
      headerFields: stub[Constants.headerFields] as? [String: String]
    )
  }

  func error(from stub: DecoyDictionary) -> [String: Any]? {
    return nil
  }

  func recordedAt(from stub: DecoyDictionary) -> String? {
    stub[Constants.recordedAt] as? String
  }
}
