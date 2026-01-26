import Foundation

@testable import pfw

struct InMemoryAuth: Auth {
  enum Error: Swift.Error, Equatable {
    case missingRedirectURL
    case missingToken
  }

  var redirectURL: URL?
  var token: String?

  init(redirectURL: URL? = nil, token: String? = nil) {
    self.redirectURL = redirectURL
    self.token = token
  }

  func start() async throws -> URL {
    guard let redirectURL else {
      throw Error.missingRedirectURL
    }
    return redirectURL
  }

  func waitForToken() async throws -> String {
    guard let token else {
      throw Error.missingToken
    }
    return token
  }
}
