import Dependencies
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

protocol PointFreeServer: Sendable {
  func downloadSkills(
    token: String,
    machine: UUID,
    whoami: String,
    sha: String?
  ) async throws -> DownloadSkillsResponse
}

enum PointFreeServerError: Swift.Error, Equatable {
  case notLoggedIn(String?)
  case serverError(String?)
  case invalidResponse
  case missingEtag
}

enum DownloadSkillsResponse: Sendable, Equatable {
  case data(Data, etag: String)
  case notModified
}

struct LivePointFreeServer: PointFreeServer {
  func downloadSkills(
    token: String,
    machine: UUID,
    whoami: String,
    sha: String?
  ) async throws -> DownloadSkillsResponse {
    let url = URL(
      string:
        "\(URL.baseURL)/account/the-way/download?token=\(token)&machine=\(machine)&whoami=\(whoami)"
    )!
    var request = URLRequest(url: url)
    request.setValue(PFW.configuration.version, forHTTPHeaderField: "X-PFW-Version")
    if let sha, !sha.isEmpty {
      request.setValue(sha, forHTTPHeaderField: "If-None-Match")
    }
    let config = URLSessionConfiguration.default
    config.urlCache = nil
    let session = URLSession(configuration: config)
    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw PointFreeServerError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200:
      guard let etag = httpResponse.value(forHTTPHeaderField: "ETag"),
        !etag.isEmpty
      else {
        throw PointFreeServerError.missingEtag
      }
      return .data(data, etag: etag)
    case 304:
      return .notModified
    case 401, 403:
      throw PointFreeServerError.notLoggedIn(String(decoding: data, as: UTF8.self))
    default:
      throw PointFreeServerError.serverError(String(decoding: data, as: UTF8.self))
    }
  }
}

enum PointFreeServerKey: DependencyKey {
  static var liveValue: any PointFreeServer { LivePointFreeServer() }
}

extension DependencyValues {
  var pointFreeServer: any PointFreeServer {
    get { self[PointFreeServerKey.self] }
    set { self[PointFreeServerKey.self] = newValue }
  }
}
