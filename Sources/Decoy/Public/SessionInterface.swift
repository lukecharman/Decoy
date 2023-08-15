import Foundation

/// `SessionInterface` defines a protocol for sessions that can handle network requests.
public protocol SessionInterface {
  /// Initializes a new session object for handling network requests, possibly stubbing the actual network calls.
  ///
  /// - Parameter stubbing: The URLSession that should be wrapped and potentially stubbed.
  init(stubbing: URLSession)

  /// Initiates a data task for the specified request, allowing for stubbed response handling.
  ///
  /// This method defines a task that retrieves the contents of the specified URL,
  /// then calls a handler upon completion. The session can decide to use the actual network
  /// or provide a stubbed response.
  ///
  /// - Parameters:
  ///   - request: The URL request object that provides the URL, cache policy, request type, and so on.
  ///   - completionHandler: The completion handler to call when the load request is complete.
  /// - Returns: A session data task that you can use to resume, pause, or cancel the request.
  func dataTask(
    with request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask

  /// Initiates a data task for the specified URL, allowing for stubbed response handling.
  ///
  /// This method provides an alternative way to create a data task, directly from a URL.
  /// It is essentially a shortcut for situations where you only have a URL (not a full URLRequest).
  ///
  /// - Parameters:
  ///   - url: The URL for which the data task should be created.
  ///   - completionHandler: The completion handler to call when the load request is complete.
  /// - Returns: A session data task that you can use to resume, pause, or cancel the request.
  func dataTask(
    with url: URL,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask
}
