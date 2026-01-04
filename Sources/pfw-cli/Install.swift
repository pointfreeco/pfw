import ArgumentParser
import Foundation

struct Install: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Download and install Point-Free Way skills."
  )

  enum Tool: String, CaseIterable, ExpressibleByArgument {
    case codex
    case claude
    var defaultInstallPath: URL {
      URL(filePath: "~/.\(rawValue)/skills/")
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

    print(String.init(decoding: data, as: UTF8.self))
    print("!!!")

    let installURL = URL(fileURLWithPath: path ?? tool.defaultInstallPath.path)

    print("Installing skills for \(tool.rawValue) into \(installURL.path)")

    try FileManager.default.createDirectory(at: installURL, withIntermediateDirectories: true)

    // TODO: Replace this stub with a real download from Point-Free.
    let stubFile = installURL.appendingPathComponent("README.txt")
    let stubText = "Skills would be downloaded here for \(tool.rawValue).\n"
    try stubText.write(to: stubFile, atomically: true, encoding: .utf8)

    print("Installed stub skills. Replace with real download when API is ready.")
  }
}
