import ArgumentParser
import Dependencies
import Foundation

struct Install: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Download and install Point-Free Way skills."
  )

  enum Tool: String, CaseIterable, ExpressibleByArgument {
    case codex
    case claude
    var defaultInstallPath: URL {
      @Dependency(\.fileSystem) var fileSystem
      return fileSystem.homeDirectoryForCurrentUser
        .appending(path: ".\(rawValue)")
        .appending(path: "skills/the-point-free-way")
    }
  }

  @Option(
    help: """
      Which AI tool to install skills for. \
      Options: \(Tool.allCases.map(\.rawValue).joined(separator: ", ")).
      """
  )
  var tool: Tool?

  @Option(help: "Directory to install skills into.")
  var path: String?

  func validate() throws {
    guard (tool != nil) != (path != nil) else {
      throw ValidationError("Provide either --tool or --path.")
    }
  }

  func run() async throws {
    try await install(shouldRetryAfterLogin: true)
  }

  private func install(shouldRetryAfterLogin: Bool) async throws {
    @Dependency(\.pointFreeServer) var pointFreeServer
    @Dependency(\.fileSystem) var fileSystem
    @Dependency(\.uuid) var uuid
    @Dependency(\.whoAmI) var whoAmI

    let token = try loadToken()
    let machine = try machine()
    let data: Data
    do {
      data = try await pointFreeServer.downloadSkills(
        token: token,
        machine: machine,
        whoami: whoAmI()
      )
    } catch let error as PointFreeServerError {
      switch error {
      case .notLoggedIn(let message):
        guard shouldRetryAfterLogin else {
          if let message, !message.isEmpty {
            print(message)
          }
          return
        }
        print("Authentication failed. Starting login flow...")
        try await performLogin(token: nil)
        print("Login complete. Retrying install...")
        try await install(shouldRetryAfterLogin: false)
        return
      case .serverError(let message):
        if let message, !message.isEmpty {
          print(message)
        }
        return
      case .invalidResponse:
        print("Unexpected response from server.")
        return
      }
    }

    let zipURL = type(of: fileSystem).temporaryDirectory.appending(path: uuid().uuidString)
    try fileSystem.write(data, to: zipURL)

    let installPath = path ?? tool?.defaultInstallPath.path ?? ""
    let installURL = URL(fileURLWithPath: installPath)
    try? fileSystem.removeItem(at: installURL)
    try fileSystem.unzipItem(at: zipURL, to: installURL)
    if let tool {
      print("Installed skills for \(tool.rawValue) into \(installURL.path)")
    } else {
      print("Installed skills into \(installURL.path)")
    }
  }
}
