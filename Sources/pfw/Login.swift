import ArgumentParser
import Dependencies
import Foundation

struct Login: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Log into your Point-Free account."
  )

  @Option(help: "Paste the token received from the browser redirect.")
  var token: String? = nil

  func run() async throws {
    try await performLogin(token: token)
  }
}

func performLogin(token: String?) async throws {
  @Dependency(\.openInBrowser) var openInBrowser

  if let token {
    try save(token: token)
    print("Saved token to \(tokenURL.path).")
    return
  }

  @Dependency(\.auth) var auth
  let redirectURL = try await auth.start()
  let loginURL = try makeLoginURL(redirectURL: redirectURL)
  print("Open this URL to log in and approve access:")
  print(loginURL.absoluteString)
  try openInBrowser(loginURL)

  print("\nWaiting for browser redirect...")
  let receivedToken = try await auth.waitForToken()
  try save(token: receivedToken)
  print("Saved token to \(tokenURL.path).")
}

func makeLoginURL(redirectURL: URL?) throws -> URL {
  @Dependency(\.whoAmI) var whoAmI

  var components = URLComponents(url: .baseURL, resolvingAgainstBaseURL: false)!
  components.path = "/account/the-way/login"
  var items = [
    URLQueryItem(name: "whoami", value: whoAmI()),
    URLQueryItem(name: "machine", value: try machine().uuidString),
  ]
  if let redirectURL {
    items.append(URLQueryItem(name: "redirect", value: redirectURL.absoluteString))
  }
  components.queryItems = items
  guard let url = components.url
  else {
    struct InvalidRedirectURL: Error {
      let components: URLComponents
    }
    throw InvalidRedirectURL(components: components)
  }
  return url
}
