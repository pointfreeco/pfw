import ArgumentParser
import Dependencies
import Foundation
#if canImport(Network)
  import Network
#endif

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
  @Dependency(\.auth) var auth
  @Dependency(\.openInBrowser) var openInBrowser

  if let token {
    try save(token: token)
    print("Saved token to \(tokenURL.path).")
    return
  }

  #if canImport(Network)
    let redirectURL = try await auth.start()
    let loginURL = try makeLoginURL(redirectURL: redirectURL)
    print("Open this URL to log in and approve access:")
    print(loginURL.absoluteString)
    try openInBrowser(loginURL)

    print("\nWaiting for browser redirect...")
    let receivedToken = try await auth.waitForToken()
    try save(token: receivedToken)
    print("Saved token to \(tokenURL.path).")
  #else
    let loginURL = try makeLoginURL(redirectURL: nil)
    print("Open this URL to log in and approve access:")
    print(loginURL.absoluteString)
    try openInBrowser(loginURL)

    print("\nAfter approving, paste the token from the redirect URL here:")
    if let receivedToken = readLine(strippingNewline: true), !receivedToken.isEmpty {
      try save(token: receivedToken)
      print("Saved token to \(tokenURL.path).")
    } else {
      print("No token entered. Run 'pfw login --token <token>' to log in.")
    }
  #endif
}

func makeLoginURL(redirectURL: URL?) throws -> URL {
  guard var components = URLComponents(string: URL.baseURL) else {
    return URL(string: "https://www.pointfree.co/account/the-way/login")!
  }
  components.path = "/account/the-way/login"
  var items = [
    URLQueryItem(name: "whoami", value: whoAmI()),
    URLQueryItem(name: "machine", value: try machine().uuidString),
  ]
  if let redirectURL {
    items.append(URLQueryItem(name: "redirect", value: redirectURL.absoluteString))
  }
  components.queryItems = items
  return components.url ?? URL(string: "https://www.pointfree.co/account/the-way/login")!
}

func whoAmI() -> String {
  #if os(macOS) || os(Linux)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/whoami")
    let output = Pipe()
    process.standardOutput = output
    do {
      try process.run()
      process.waitUntilExit()
      let data = output.fileHandleForReading.readDataToEndOfFile()
      let value = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if let value, !value.isEmpty {
        return value
      }
    } catch {
      // Fall back to the system username.
    }
  #endif
  let fallback = NSUserName()
  return fallback.isEmpty ? "unknown" : fallback
}
