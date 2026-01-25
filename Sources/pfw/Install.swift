import ArgumentParser
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

  @Option(help: "Directory to install skills into. Use '.' or 'current' for current directory.")
  var path: String?

  func run() async throws {
    try await install(shouldRetryAfterLogin: true)
  }

  // MARK: - Testable Helper Functions

  static func isCurrentDirectoryPath(_ path: String?) -> Bool {
    path == "." || path == "current"
  }

  static func validateInstallPath(_ installPath: String, tool: Tool) -> Bool {
    let expectedPattern = ".\(tool.rawValue)/skills"
    return installPath.contains(expectedPattern)
  }

  static func resolveInstallURL(
    path: String?,
    tool: Tool,
    currentDirectory: String = FileManager.default.currentDirectoryPath
  ) -> URL {
    if isCurrentDirectoryPath(path) {
      return URL(fileURLWithPath: currentDirectory)
    } else {
      return URL(fileURLWithPath: path ?? tool.defaultInstallPath.path)
    }
  }

  private func install(shouldRetryAfterLogin: Bool) async throws {
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

    let zipURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try data.write(to: zipURL)

    // Determine if installing to current directory
    let isCurrentDirectory = Self.isCurrentDirectoryPath(path)
    let installURL = Self.resolveInstallURL(path: path, tool: tool)

    // Verify the install path is in the expected location (only if custom path provided)
    if path != nil {
      let installPath = installURL.path

      guard Self.validateInstallPath(installPath, tool: tool) else {
        print("Error: Install path is not in the expected location.")
        print("")
        print("The install path must contain '.\(tool.rawValue)/skills' in it.")
        print("")
        print("Valid options:")
        print("  1. Use default path: pfw install --tool \(tool.rawValue)")
        print("     Installs to: ~/.\(tool.rawValue)/skills/the-point-free-way")
        print("")
        print("  2. Use custom path ending with '.\(tool.rawValue)/skills':")
        print("     pfw install --tool \(tool.rawValue) --path /your/project/.\(tool.rawValue)/skills")
        print("")
        print("Current install path: \(installPath)")
        throw ExitCode.failure
      }

      // Ask for confirmation when using custom path
      print("You are about to install into:")
      print("  \(installPath)")
      print("\nThis will merge new skills with existing ones without removing current files.")
      print("Continue? (yes/no): ", terminator: "")

      guard let response = readLine()?.lowercased(),
            response == "yes" || response == "y" else {
        print("Installation cancelled.")
        throw ExitCode.success
      }
    }

    // Always merge - never remove existing files
    // The zip contains a top-level "skills" folder, so we extract to a temp location
    // and then move the contents of the skills folder to the target location
    let tempExtractURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempExtractURL, withIntermediateDirectories: true)

    try FileManager.default.unzipItem(at: zipURL, to: tempExtractURL)

    // The zip extracts to tempExtractURL/skills/, we want to move its contents to installURL
    let extractedSkillsURL = tempExtractURL.appending(path: "skills")

    // Ensure target directory exists
    try FileManager.default.createDirectory(at: installURL, withIntermediateDirectories: true)

    // Move each skill from the extracted location to the target
    let skillDirs = try FileManager.default.contentsOfDirectory(
      at: extractedSkillsURL,
      includingPropertiesForKeys: nil
    )

    for skillURL in skillDirs {
      let targetURL = installURL.appending(path: skillURL.lastPathComponent)

      // If the skill already exists, remove it first (we're replacing individual skills, not the whole directory)
      if FileManager.default.fileExists(atPath: targetURL.path) {
        try FileManager.default.removeItem(at: targetURL)
      }

      try FileManager.default.moveItem(at: skillURL, to: targetURL)
    }

    // Clean up temp directory
    try? FileManager.default.removeItem(at: tempExtractURL)
    try? FileManager.default.removeItem(at: zipURL)

    if isCurrentDirectory {
      print("Successfully merged skills into \(installURL.path)")
    } else {
      print("Installed and merged skills for \(tool.rawValue) into \(installURL.path)")
    }
  }
}
