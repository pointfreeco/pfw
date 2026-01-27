import Dependencies
import Foundation

@testable import pfw

actor InMemoryPointFreeServer: PointFreeServer {
  @Dependency(\.continuousClock) var clock
  var results: [Result<DownloadSkillsResponse, PointFreeServerError>] = []

  init(results: [Result<DownloadSkillsResponse, PointFreeServerError>]) {
    self.results = results
  }

  init(result: Result<DownloadSkillsResponse, PointFreeServerError>) {
    self.results = [result]
  }

  func downloadSkills(
    token: String,
    machine: UUID,
    whoami: String,
    sha: String?
  ) async throws -> DownloadSkillsResponse {
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
