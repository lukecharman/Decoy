import Foundation

/// A protocol defining a queue system for managing mocked responses.
///
/// Implementations of this protocol allow you to store and later retrieve
/// mocked responses for specific URLs, enabling deterministic testing of network calls.
public protocol QueueInterface {
  /// A dictionary mapping URLs to an array of queued mocked responses.
  ///
  /// Each URL key is associated with an array of `Stub.Response` objects,
  /// which are returned in a last-in, first-out (LIFO) order when requested.
  var queuedResponses: [Stub.Identifier: [Stub.Response]] { get set }

  /// Enqueues a mocked response for a specific URL.
  ///
  /// - Parameter Stub: A `Stub` instance containing both the URL and its associated response.
  ///   The response is added to the queue for that URL.
  func queue(stub: Stub, origin: Queue.ResponseOrigin)

  /// Synchronously retrieves and removes the next queued response for a given URL.
  ///
  /// - Parameter url: The URL for which to retrieve the next mocked response.
  /// - Returns: An optional `Stub.Response` if one exists in the queue; otherwise, `nil`.
  func nextQueuedResponse(for identifier: Stub.Identifier) -> Stub.Response?

  /// Removes all queued mocked responses and resets the internal store.
  ///
  /// Use this method to remove all stubbed responses that have been enqueued, returning the queue to an empty state.
  ///
  /// Conforming implementations should use this to ensure a clean test state between test runs or scenarios, preventing cross-test contamination and ensuring deterministic behavior.
  func clear()
}

/// A class responsible for managing a queue of mocked responses.
///
/// This class implements `QueueInterface` and stores mock responses in a dictionary keyed by URL.
/// When a network request is intercepted, the next mocked response (if any) is returned.
public class Queue: QueueInterface {
  public enum ResponseOrigin: String {
    case specific = "specific"
    case shared = "shared"
  }
  /// A dictionary mapping URLs to an array of `Stub.Response` objects.
  ///
  /// Each URL key stores an array of responses, where the most recent response (inserted last)
  /// is returned first when requested.
  public var queuedResponses = [Stub.Identifier: [Stub.Response]]()
  private var initialSpecificQueuedResponses = [Stub.Identifier: [Stub.Response]]()
  private var initialSharedQueuedResponses = [Stub.Identifier: [Stub.Response]]()

  private let isXCUI: Bool

  private let logger: LoggerInterface

  init(isXCUI: Bool, logger: LoggerInterface) {
    self.isXCUI = isXCUI
    self.logger = logger
  }

  /// Enqueues a mocked response for a specific URL.
  ///
  /// - Parameter Stub: A `Stub` instance that contains the URL and the associated response.
  ///   If no responses exist for that URL, an array is created, and then the response is inserted
  ///   at the beginning of the array to maintain a LIFO order.
  public func queue(stub: Stub, origin: ResponseOrigin) {
    queuedResponses[stub.identifier, default: []].insert(stub.response, at: 0)

    queue(stub, in: origin)
  }

  private func queue(_ stub: Stub, in origin: ResponseOrigin) {
    switch origin {
    case .shared:
      initialSharedQueuedResponses[stub.identifier, default: []].insert(stub.response, at: 0)
    case .specific:
      initialSpecificQueuedResponses[stub.identifier, default: []].insert(stub.response, at: 0)
    }
  }

  /// Synchronously retrieves and removes the next queued response for a given URL.
  ///
  /// - Parameter url: The URL for which to retrieve the next mocked response.
  /// - Returns: The next `Stub.Response` if available; otherwise, `nil`.
  ///
  /// This method removes and returns the last element of the array for the specified URL,
  /// which corresponds to the most recently added response.
  public func nextQueuedResponse(for identifier: Stub.Identifier) -> Stub.Response? {
    guard isXCUI else { return nil }

    if case .url(let url) = identifier {
      if let stub = queuedResponses[.url(url)]?.popLast() {
        logger.info("Providing decoy for \(url)")
        return stub
      } else {
        logMissingIdentifier(identifier)
        return nil
      }
    } else if case .signature(let graphQLSignature) = identifier {
      if let stub = queuedResponses[.signature(graphQLSignature)]?.popLast() {
        logger.info("Providing decoy for \(graphQLSignature)")
        return stub
      } else {
        logMissingIdentifier(identifier)
        return nil
      }
    } else {
      return nil
    }
  }

  /**
   Removes all queued stub responses, effectively resetting the internal response store.
   
   This method clears all stored mocked responses for every URL or signature, returning the queue to an empty state.
   
   Typically, you use this method during test teardown or when you need to reset the `Decoy` queue between test scenarios to ensure isolation and prevent cross-test contamination.
   */
  public func clear() {
    queuedResponses.removeAll()
  }

  /**
     Logs a detailed warning when no queued mock response exists for the given stub identifier.

   - Parameter identifier: The `Stub.Identifier` (either `.url` or `.signature`) that
                          could not be matched with a queued decoy.

     This method logs the identifier of the missing mock.
     Logs a warning message that may include:
     - The initial queued count if mocks were present but already consumed.
     - For GraphQL signatures, a comparison against queued signatures to highlight mismatches in endpoint,
       operation name, variables, or query.
  */
  private func logMissingIdentifier(_ identifier: Stub.Identifier) {
    var warningMessage = ""

    switch identifier {
    case .url(let url):
      warningMessage += "No decoy was queued for url: \(url) | "
    case .signature(let graphQLSignature):
      warningMessage += "No decoy was queued for signature: \(graphQLSignature) | "
    }

    appendCountInQueue(identifier: identifier, origin: .shared, log: &warningMessage)
    appendCountInQueue(identifier: identifier, origin: .specific, log: &warningMessage)

    appendPossibleMisses(identifier, origin: .shared, log: &warningMessage)
    appendPossibleMisses(identifier, origin: .specific, log: &warningMessage)

    logger.warning(warningMessage)
  }

  private func appendCountInQueue(
    identifier: Stub.Identifier,
    origin: ResponseOrigin,
    log: inout String
  ) {
    let queue = getQueue(for: origin)

    if let count = queue[identifier]?.count {
      log += "Mocks were present but already consumed in \(origin.rawValue) queue. Initial count: \(count) "
    }
  }

  private func appendPossibleMisses(
    _ identifier: Stub.Identifier,
    origin: ResponseOrigin,
    log: inout String
  ) {
    guard let graphQLSignature = getSignature(for: identifier) else {
      return
    }

    let queue = getQueue(for: origin)

    let possibleMisses = queue.keys.filter { id in
      switch id {
      case .signature:
        if id.stringValue == identifier.stringValue {
          return true
        }
        return false
      case .url:
        return false
      }
    }

    if possibleMisses.isEmpty {
      log += "No similar mocks found in \(origin.rawValue) queue to compare | "
    }

    possibleMisses.forEach { id in
      switch id {
      case .signature(let queuedGraphQLSignature):
        if queuedGraphQLSignature.endpoint != graphQLSignature.endpoint {
          log +=
          "ENDPOINT MISMATCH IN \(origin.rawValue.uppercased()): EXPECTED: \(graphQLSignature.endpoint) | QUEUED: \(queuedGraphQLSignature.endpoint)"
        }
        if queuedGraphQLSignature.query != graphQLSignature.query {
          log +=
          "QUERY MISMATCH IN \(origin.rawValue.uppercased()): EXPECTED: \(graphQLSignature.query) | QUEUED: \(queuedGraphQLSignature.query)"
        }
      case .url:
        break
      }
    }
  }
}

extension Queue {
  private func getSignature(for identifier: Stub.Identifier) -> GraphQLSignature? {
    switch identifier {
    case .signature(let signature):
      return signature
    case .url:
      return nil
    }
  }

  private func getQueue(for origin: ResponseOrigin) -> [Stub.Identifier : [Stub.Response]] {
    switch origin {
    case .shared:
      return initialSharedQueuedResponses
    case .specific:
      return initialSpecificQueuedResponses
    }
  }
}
