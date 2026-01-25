import ArgumentParser
import Dependencies
import Foundation
import ZIPFoundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

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
        .appending(path: rawValue)
        .appending(path: "skills/the-point-free-way")
    }
  }

  @Option(
    help: """
      Which AI tool to install skills for. \
      Options: \(Tool.allCases.map(\.rawValue).joined(separator: ", ")).
      """
  )
  var tool: Tool

  @Option(help: "Directory to install skills into.")
  var path: String?

  func run() async throws {
    try await install(shouldRetryAfterLogin: true)
  }

  private func install(shouldRetryAfterLogin: Bool) async throws {
    @Dependency(\.uuid) var uuid
    let token = try loadToken()
    let machine = try machine()
    let whoami = whoAmI()

    let (data, response) = try await URLSession.shared
      .data(
        from: URL(
          string:
            "\(URL.baseURL)/account/the-way/download?token=\(token)&machine=\(machine)&whoami=\(whoami)"
        )!
      )

    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
    if statusCode == 401 || statusCode == 403 {
      guard shouldRetryAfterLogin else {
        print(String(decoding: data, as: UTF8.self))
        return
      }
      print("Authentication failed. Starting login flow...")
      try await performLogin(token: nil)
      print("Login complete. Retrying install...")
      try await install(shouldRetryAfterLogin: false)
      return
    }

    guard statusCode == 200 else {
      print(String(decoding: data, as: UTF8.self))
      return
    }

    let zipURL = URL.temporaryDirectory.appending(path: uuid().uuidString)
    try data.write(to: zipURL)

    let installURL = URL(fileURLWithPath: path ?? tool.defaultInstallPath.path)
    try? FileManager.default.removeItem(at: installURL)
    try FileManager.default.unzipItem(at: zipURL, to: installURL)
    print("Installed skills for \(tool.rawValue) into \(installURL.path)")
  }
}
