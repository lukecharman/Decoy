import Foundation

protocol LoaderInterface {
  func loadJSON(from url: URL) -> [Decoy]?
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
  }

  /// Looks for a JSON file at the given URL, and decodes its contents into an array of stubbed responses.
  ///
  /// - Parameters:
  ///   - url: The location at which to look for a JSON file containing ordered, stubbed responses.
  ///
  /// - Returns: An optional array of `Decoy`s, read sequentially from the named JSON.
  func loadJSON(from url: URL) -> [Decoy]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let json = try? JSONSerialization.jsonObject(with: data) as? DecoyArray else { return nil }

    return json.compactMap { stubMark(from: $0) }
  }

  private func stubMark(from json: [String: Any]) -> Decoy? {
    guard let urlString = json[Constants.url] as? String else { return nil }
    guard let url = URL(string: urlString) else { return nil }
    guard let stub = json[Constants.stub] as? DecoyDictionary else { return nil }

    let data = data(from: stub)
    let urlResponse = urlResponse(to: url, from: stub)
    let response = Decoy.Response(data: data, urlResponse: urlResponse, error: nil)

    return Decoy(url: url, response: response)
  }

  private func data(from stub: DecoyDictionary) -> Data? {
    guard let json = stub[Constants.json] else { return nil }
    return try? JSONSerialization.data(withJSONObject: json)
  }

  private func urlResponse(to url: URL, from stub: DecoyDictionary) -> HTTPURLResponse? {
    HTTPURLResponse(
      url: url,
      statusCode: stub[Constants.statusCode] as? Int ?? 200,
      httpVersion: stub[Constants.httpVersion] as? String,
      headerFields: stub[Constants.headerFields] as? [String: String]
    )
  }

  private func error(from stub: DecoyDictionary) -> [String: Any]? {
    return nil
  }
}