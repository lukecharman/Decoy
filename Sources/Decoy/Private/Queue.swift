import Foundation

/// A protocol that defines the interface for managing queued responses.
protocol QueueInterface {
  /// A dictionary that holds queued stubs for specific URLs.
  var queuedResponses: [URL: [Stub]] { get set }

  /// Queues a stubbed response to be used later.
  /// - Parameter stub: The stubbed response to be queued.
  func queue(stub: Stub)

  /// Dispatches the next queued response for a specific URL.
  /// - Parameters:
  ///   - url: The URL for which a response is to be dispatched.
  ///   - completion: The completion handler to be called after the response is dispatched.
  /// - Returns: `true` if a queued response was dispatched, `false` otherwise.
  func dispatchNextQueuedResponse(for url: URL, to completion: @escaping DataTask.CompletionHandler) -> Bool
}

/// Used to queue stubbed responses to calls to various endpoints.
class Queue: QueueInterface {
  /// A set of responses. Calls to URLs matching the keys will sequentially be stubbed with data in the response.
  var queuedResponses = [URL: [Stub]]()

  /// Queues a provided response to a given URL. With this function, you can stub the data returned, as well as the
  /// `URLResponse` and any potential `Error`s, to see how your app handles them.
  ///
  /// - Parameters:
  ///   - stub: The `Stub` containing URL and response information for the stub.
  func queue(stub: Stub) {
    if queuedResponses[stub.url] == nil {
      queuedResponses[stub.url] = []
    }

    queuedResponses[stub.url]?.insert(stub, at: 0)
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

    completion((next.response.data, nil, nil))

    return true
  }
}
