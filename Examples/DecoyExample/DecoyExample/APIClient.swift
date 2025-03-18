import Foundation

/// Note: this `APIClient` has no knowledge of Decoy, and nor should it.
struct APIClient {
  private let session: URLSession
  private let fruitEndpoint = "https://fruityvice.com/api/fruit/"
  private let catEndpoint = "https://catfact.ninja/fact"

  init(session: URLSession) {
    self.session = session
  }

  func fetchApple(completion: @escaping (Fruit?) -> Void) {
    fetchFruit("apple", completion: completion)
  }

  func fetchBanana(completion: @escaping (Fruit?) -> Void) {
    fetchFruit("banana", completion: completion)
  }

  func fetchCatFact(completion: @escaping (String?) -> Void) {
    guard let url = URL(string: catEndpoint) else { return completion(nil) }

    session.dataTask(with: URLRequest(url: url)) { data, response, error in
      guard let data else { return completion(nil) }
      let decoder = JSONDecoder()
      let fact = try? decoder.decode(CatFact.self, from: data)
      completion(fact?.fact ?? nil)
    }.resume()
  }

  func fetchFruit(_ string: String, completion: @escaping (Fruit?) -> Void) {
    guard let url = URL(string: fruitEndpoint.appending(string)) else { return completion(nil) }

    session.dataTask(with: URLRequest(url: url)) { data, response, error in
      guard let data else { return completion(nil) }
      let decoder = JSONDecoder()
      let fruit = try? decoder.decode(Fruit.self, from: data)
      completion(fruit ?? nil)
    }.resume()
  }
}

struct Fruit: Decodable {
  let name: String
}

struct CatFact: Decodable {
  let fact: String
}
