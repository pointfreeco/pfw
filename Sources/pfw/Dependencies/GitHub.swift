import Dependencies
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

protocol GitHub: Sendable {
  func fetchTags(owner: String, repo: String) async throws -> [GitHubTag]
}

struct GitHubTag: Decodable, Equatable, Sendable {
  var name: String
}

struct LiveGitHub: GitHub {
  func fetchTags(owner: String, repo: String) async throws -> [GitHubTag] {
    let (data, _) = try await URLSession.shared.data(
      from: URL(string: "https://api.github.com/repos/\(owner)/\(repo)/tags")!
    )
    return try JSONDecoder().decode([GitHubTag].self, from: data)
  }
}

enum GitHubKey: DependencyKey {
  static var liveValue: any GitHub { LiveGitHub() }
}

extension DependencyValues {
  var gitHub: any GitHub {
    get { self[GitHubKey.self] }
    set { self[GitHubKey.self] = newValue }
  }
}
