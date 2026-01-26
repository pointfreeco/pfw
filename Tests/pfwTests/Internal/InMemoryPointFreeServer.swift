import Dependencies
import Foundation

@testable import pfw

actor InMemoryPointFreeServer: PointFreeServer {
  @Dependency(\.continuousClock) var clock
  var results: [Result<Data, PointFreeServerError>] = []

  init(results: [Result<Data, PointFreeServerError>]) {
    self.results = results
  }

  init(result: Result<Data, PointFreeServerError>) {
    self.results = [result]
  }

  func downloadSkills(token: String, machine: UUID, whoami: String) async throws -> Data {
    guard !results.isEmpty
    else {
      throw PointFreeServerError.invalidResponse
    }
    let result = results.removeFirst()
    if !results.isEmpty {
      try await clock.sleep(for: .seconds(1))
    }
    return try result.get()
  }
}
