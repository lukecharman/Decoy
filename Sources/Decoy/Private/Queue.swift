import Foundation

protocol QueueInterface {
  var queuedResponses: [URL: [Stub.Response]] { get set }

  func queue(decoy: Stub)
  func dispatchNextQueuedResponse(for url: URL, to completion: @escaping DataTask.CompletionHandler) -> Bool
}

/// Used to queue stubbed responses to calls to various endpoints.
class Queue: QueueInterface {

  /// A set of responses. Calls to URLs matching the keys will sequentially be stubbed with data in the response.
  var queuedResponses = [URL: [Stub.Response]]()

  /// Queues a provided response to a given URL. With this function, you can stub the data returned, as well as the
  /// `URLResponse` and any potential `Error`s, to see how your app handles them.
  ///
  /// - Parameters:
  ///   - decoy: The `Decoy` containing URL and response information for the stub.
  func queue(decoy: Stub) {
    if queuedResponses[decoy.url] == nil {
      queuedResponses[decoy.url] = []
    }

    queuedResponses[decoy.url]?.insert(decoy.response, at: 0)
  }

  /// Dispatches the next queued response for the provided URL. Checks the queued response array for responses
  /// matching the given URL, and returns and removes the most recently added.
  ///
  /// - Parameters:
  ///   - url: The url for which the next queued `response` will return.
  ///   - completion: A closure to be called with the queued response.
  func dispatchNextQueuedResponse(for url: URL, to completion: @escaping DataTask.CompletionHandler) -> Bool {
    guard let next = queuedResponses[url]?.popLast() else {
      return false
    }

    completion((next.data, nil, nil))

    return true
  }

}
