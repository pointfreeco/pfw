import ArgumentParser
import Foundation
import Synchronization

#if canImport(Network)
  import Network
#endif

struct Login: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Log into your Point-Free account."
  )

  @Option(help: "Paste the token received from the browser redirect.")
  var token: String?

  func run() async throws {
//    do {
//      _ = try loadToken()
//      print("Already logged in. Logout before trying to log in again.")
//      return
//    } catch {}

    if let token {
      try save(token: token)
      print("Saved token to \(tokenURL.path).")
      return
    }

    #if canImport(Network)
      let server = try LocalAuthServer()
      let redirectURL = try await server.start()
      let loginURL = try makeLoginURL(redirectURL: redirectURL)
      print("Open this URL to log in and approve access:")
      print(loginURL.absoluteString)
      try openInBrowser(loginURL)

      print("\nWaiting for browser redirect...")
      let receivedToken = try await server.waitForToken()
      try save(token: receivedToken)
      print("Saved token to \(tokenURL.path).")
    #else
      let loginURL = makeLoginURL(redirectURL: nil)
      print("Open this URL to log in and approve access:")
      print(loginURL.absoluteString)
      try openInBrowser(loginURL)

      print("\nAfter approving, paste the token from the redirect URL here:")
      if let line = readLine(strippingNewline: true), !line.isEmpty {
        try save(token: line)
        print("Saved token to \(storeURL.path).")
      } else {
        print("No token entered. You can run `pfw login --token <token>` later.")
      }
    #endif
  }
}

func openInBrowser(_ url: URL) throws {
  #if os(macOS)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [url.absoluteString]
    try process.run()
  #elseif os(Linux)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
    process.arguments = [url.absoluteString]
    try process.run()
  #else
    print("Please open this URL in your browser: \(url.absoluteString)")
  #endif
}

func makeLoginURL(redirectURL: URL?) throws -> URL {
  guard var components = URLComponents(string: URL.baseURL) else {
    return URL(string: "https://www.pointfree.co/account/the-way/login")!
  }
  components.path = "/account/the-way/login"
  var items = [
    URLQueryItem(name: "whoami", value: whoAmI()),
    URLQueryItem(name: "machine", value: try machine().uuidString)
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

#if canImport(Network)
  actor LocalAuthServer {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "pfw.auth.server")
    private var tokenContinuation: CheckedContinuation<String, Error>?

    init() throws {
      listener = try NWListener(using: .tcp, on: .any)
    }

    func start() async throws -> URL {
      let hasStarted = Mutex(false)
      listener.stateUpdateHandler = { state in
        guard state == .ready
        else { return }
        hasStarted.withLock { $0 = true }
      }
      listener.newConnectionHandler = { [weak self] connection in
        Task {
          connection.start(queue: self?.queue ?? .main)
          await self?.receiveToken(from: connection)
        }
      }
      listener.start(queue: queue)
      while !hasStarted.withLock(\.self) {
        try await Task.sleep(for: .seconds(0.1))
        // TODO: Timeout if takes too long
      }
      guard let port = listener.port else {
        throw ValidationError("Unable to determine callback port.")
      }
      return URL(string: "http://127.0.0.1:\(port)/callback")!
    }

    func waitForToken() async throws -> String {
      try await withCheckedThrowingContinuation { continuation in
        tokenContinuation = continuation
      }
    }

    private func receiveToken(from connection: NWConnection) {
      connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) {
        [weak self] data, _, _, error in
        Task {
          if let error {
            await self?.finish(with: .failure(error))
            connection.cancel()
            return
          }
          guard let data, let request = String(data: data, encoding: .utf8) else {
            await self?.finish(with: .failure(ValidationError("Invalid request.")))
            connection.cancel()
            return
          }
          let token = Self.token(from: request)
          if let token {
            await self?.respond(connection: connection, success: true)
            await self?.finish(with: .success(token))
          } else {
            await self?.respond(connection: connection, success: false)
            await self?.finish(with: .failure(ValidationError("Missing token in redirect.")))
          }
          connection.cancel()
        }
      }
    }

    private func respond(connection: NWConnection, success: Bool) {
      let message =
        success
        ? "You can return to the terminal. Login complete."
        : "Login failed. Please return to the terminal."
      let body = "<html><body><p>\(message)</p></body></html>"
      let response = """
        HTTP/1.1 200 OK\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """
      connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })
    }

    private func finish(with result: Result<String, Error>) {
      listener.cancel()
      tokenContinuation?.resume(with: result)
      tokenContinuation = nil
    }

    private static func token(from request: String) -> String? {
      return String(
        request
          .dropFirst("GET /callback?token=".count)
          .prefix(while: { $0 != " " })
      )
    }
  }
#endif
