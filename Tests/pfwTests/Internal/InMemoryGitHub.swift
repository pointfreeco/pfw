import Foundation

@testable import pfw

struct InMemoryGitHub: GitHub {
  var tags: [GitHubTag]

  func fetchTags(owner: String, repo: String) async throws -> [GitHubTag] {
    tags
  }
}
