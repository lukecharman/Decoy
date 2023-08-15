import Foundation

/// A subclass of `URLSession` which injects Decoy's subclassed `URLSessionDataTask` objects.
public class Session: URLSession, SessionInterface {
  /// The underlying `URLSession` being stubbed.
  let urlSession: URLSession

  /// Used to record responses from calls made to this session.
  var recorder: RecorderInterface = Decoy.shared.recorder

  /// Initialise a `Session` which wraps another `URLSession` and can stub its data tasks.
  ///
  /// - Parameters:
  ///   - session: The underlying `URLSession` being stubbed.
  ///
  /// - Returns: An instance of `Session` which will stub calls as requested.
  required public init(stubbing session: URLSession = .shared) {
    self.urlSession = session
  }

  /// Create a `DecoyURLSessionDataTask` (as a standard `URLSessionDataTask`)
  /// which can be used to return stubbed responses from the response queue.
  ///
  /// - Parameters:
  ///   - request: The request to be stubbed.
  ///   - completionHandler: A callback which will be called with eithert stubbed or real data.
  ///
  /// - Returns: An instance of `DecoyURLSessionDataTask` typed as a `URLSessionDataTask`.
  override public func dataTask(
    with request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask {
    let superTask = urlSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in
      guard let self else { return }
      if self.recorder.shouldRecord, let url = request.url {
        self.recorder.record(url: url, data: data, response: response, error: error)
      }
      completionHandler(data, response, error)
    })

    return DataTask(stubing: superTask, completionHandler: completionHandler)
  }

  /// Create a `DecoyURLSessionDataTask` (as a standard `URLSessionDataTask`)
  /// which can be used to return stubbed responses from the response queue.
  ///
  /// - Parameters:
  ///   - url: The URL from which responses will be stubbed.
  ///   - completionHandler: A callback which will be called with eithert stubbed or real data.
  ///
  /// - Returns: An instance of `DecoyURLSessionDataTask` typed as a `URLSessionDataTask`.
  override public func dataTask(
    with url: URL,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask {
    DataTask(
      stubing: urlSession.dataTask(with: url, completionHandler: { [weak self] data, response, error in
        guard let self else { return }
        if self.recorder.shouldRecord {
          self.recorder.record(url: url, data: data, response: response, error: error)
        }
        completionHandler(data, response, error)
      }),
      completionHandler: completionHandler
    )
  }
}
