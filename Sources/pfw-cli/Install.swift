import ArgumentParser
import Foundation
import ZIPFoundation

struct Install: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Download and install Point-Free Way skills."
  )

  enum Tool: String, CaseIterable, ExpressibleByArgument {
    case codex
    case claude
    var defaultInstallPath: URL {
      URL(filePath: "~/.\(rawValue)/skills/the-point-free-way")
    }
  }

  @Option(
    help: """
      Which AI tool to install skills for. \
      Options: \(Tool.allCases.map(\.rawValue).joined(separator: ", ")).
      """
  )
  var tool: Tool = .codex

  @Option(help: "Directory to install skills into.")
  var path: String?

  func run() async throws {
    let token = try loadToken()
    let machine = try machine()
    let whoami = whoAmI()

    let (data, _) = try await URLSession.shared
      .data(
        from: URL(
          string: "\(URL.baseURL)/account/the-way/download?token=\(token)&machine=\(machine)&whoami=\(whoami)"
        )!
      )

    let zipURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try data.write(to: zipURL)

    let installURL = URL(fileURLWithPath: path ?? tool.defaultInstallPath.path)
    try? FileManager.default.removeItem(at: installURL)
    try FileManager.default.unzipItem(at: zipURL, to: installURL)
    print("Installed skills for \(tool.rawValue) into \(installURL.path)")
  }
}
