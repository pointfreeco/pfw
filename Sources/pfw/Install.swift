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
    case cursor
    case copilot
    case kiro
    case gemini
    case antigravity

    func symlinkPath(workspace: Bool) -> URL {
      if workspace {
        // Workspace-specific paths
        switch self {
        case .copilot:
          return URL(filePath: ".github/skills")
        case .antigravity:
          return URL(filePath: ".agent/skills")
        default:
          return URL(filePath: ".\(rawValue)/skills")
        }
      } else {
        // Global (user-level) paths
        switch self {
        case .antigravity:
          return URL(filePath: "~/.gemini/antigravity/global_skills")
        default:
          return URL(filePath: "~/.\(rawValue)/skills")
        }
      }
    }
  }

  @Option(
    parsing: .upToNextOption,
    help: """
      Which AI tools to create symlinks for. \
      Options: \(Tool.allCases.map(\.rawValue).joined(separator: ", ")). \
      Can specify multiple: --tools cursor claude codex
      """
  )
  var tools: [Tool] = []

  @Flag(help: "Install for all supported AI tools.")
  var all: Bool = false

  @Flag(help: "Store skills locally in project (.pfw/skills) instead of globally in home (~/.pfw/skills).")
  var local: Bool = false

  @Flag(help: "Create symlinks in workspace directories (.cursor/skills) instead of global directories (~/.cursor/skills).")
  var workspace: Bool = false

  @Option(help: "Custom directory to install skills into. Use '.' for current directory.")
  var path: String?

  var skillsStoragePath: URL {
    if local {
      return URL(filePath: ".pfw/skills")
    } else {
      return URL(filePath: "~/.pfw/skills")
    }
  }

  func run() async throws {
    try await install(shouldRetryAfterLogin: true)
  }

  // MARK: - Testable Helper Functions

  static func isCurrentDirectoryPath(_ path: String?) -> Bool {
    path == "."
  }

  static func validateInstallPath(_ installPath: String) -> Bool {
    // Allow any path that contains /skills to support different directory naming conventions
    return installPath.contains("/skills")
  }

  func resolveInstallURL(
    path: String?,
    currentDirectory: String = FileManager.default.currentDirectoryPath
  ) -> URL {
    if Self.isCurrentDirectoryPath(path) {
      return URL(fileURLWithPath: currentDirectory)
    } else {
      return URL(fileURLWithPath: path ?? skillsStoragePath.path)
    }
  }

  static func promptForTools() -> [Tool] {
    print("Which AI tools would you like to install skills for?")
    print("")
    for (index, tool) in Tool.allCases.enumerated() {
      print("  \(index + 1). \(tool.rawValue)")
    }
    print("  \(Tool.allCases.count + 1). All of the above")
    print("")
    print("Enter numbers separated by spaces (e.g., '1 3 5'): ", terminator: "")

    guard let input = readLine()?.trimmingCharacters(in: .whitespaces),
          !input.isEmpty else {
      print("No selection made. Defaulting to Codex.")
      return [.codex]
    }

    let selections = input.split(separator: " ").compactMap { Int($0) }

    if selections.contains(Tool.allCases.count + 1) {
      return Tool.allCases
    }

    let selectedTools = selections.compactMap { index -> Tool? in
      guard index > 0 && index <= Tool.allCases.count else { return nil }
      return Tool.allCases[index - 1]
    }

    return selectedTools.isEmpty ? [.codex] : selectedTools
  }

  static func createSymlink(from symlinkPath: URL, to targetPath: URL) throws {
    let fileManager = FileManager.default
    let expandedSymlinkPath = URL(fileURLWithPath: NSString(string: symlinkPath.path).expandingTildeInPath)
    let expandedTargetPath = URL(fileURLWithPath: NSString(string: targetPath.path).expandingTildeInPath)

    // Create parent directory if needed
    let parentDir = expandedSymlinkPath.deletingLastPathComponent()
    try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)

    // Remove existing symlink or directory if present
    if fileManager.fileExists(atPath: expandedSymlinkPath.path) {
      try fileManager.removeItem(at: expandedSymlinkPath)
    }

    // Create symlink
    try fileManager.createSymbolicLink(at: expandedSymlinkPath, withDestinationURL: expandedTargetPath)
  }

  private func install(shouldRetryAfterLogin: Bool) async throws {
    // Local skills must use workspace symlinks (can't symlink different projects to same global location)
    if local && !workspace {
      print("Note: --local automatically enables --workspace")
      print("(Local skills from different projects would conflict if symlinked globally)")
      print("")
    }
    let useWorkspace = workspace || local

    // Determine which tools to install for
    var selectedTools = tools
    if all {
      selectedTools = Tool.allCases
    } else if selectedTools.isEmpty {
      // Interactive prompt
      selectedTools = Self.promptForTools()
    }

    // Download skills
    let token = try loadToken()
    let machine = try machine()
    let whoami = whoAmI()

    print("Downloading Point-Free Way skills...")
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

    // Determine install location
    let isCurrentDirectory = Self.isCurrentDirectoryPath(path)
    let installURL = resolveInstallURL(path: path)

    // Verify the install path if custom path provided
    if path != nil {
      let installPath = installURL.path

      guard Self.validateInstallPath(installPath) else {
        print("Error: Install path is not in the expected location.")
        print("")
        print("The install path must contain '/skills' in it.")
        print("")
        print("Valid options:")
        print("  1. Use default path: pfw install")
        print("     Installs to: ~/.pfw/skills/")
        print("")
        print("  2. Use local path: pfw install --local")
        print("     Installs to: .pfw/skills/")
        print("")
        print("  3. Use custom path containing '/skills':")
        print("     pfw install --path /your/project/.config/skills")
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

    // Extract skills to install location
    let tempExtractURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempExtractURL, withIntermediateDirectories: true)
    try FileManager.default.unzipItem(at: zipURL, to: tempExtractURL)

    // The zip extracts to tempExtractURL/skills/
    let extractedSkillsURL = tempExtractURL.appending(path: "skills")

    // Ensure target directory exists
    let expandedInstallURL = URL(fileURLWithPath: NSString(string: installURL.path).expandingTildeInPath)
    try FileManager.default.createDirectory(at: expandedInstallURL, withIntermediateDirectories: true)

    // Move each skill from the extracted location to the target
    let skillDirs = try FileManager.default.contentsOfDirectory(
      at: extractedSkillsURL,
      includingPropertiesForKeys: nil
    )

    for skillURL in skillDirs {
      let targetURL = expandedInstallURL.appending(path: skillURL.lastPathComponent)

      // If the skill already exists, remove it first
      if FileManager.default.fileExists(atPath: targetURL.path) {
        try FileManager.default.removeItem(at: targetURL)
      }

      try FileManager.default.moveItem(at: skillURL, to: targetURL)
    }

    // Clean up temp files
    try? FileManager.default.removeItem(at: tempExtractURL)
    try? FileManager.default.removeItem(at: zipURL)

    print("✓ Skills installed to \(expandedInstallURL.path)")

    // Create symlinks for each selected tool (unless installing to current directory)
    var failedSymlinks: [Tool] = []
    if !isCurrentDirectory {
      print("")
      let storageLocation = local ? "local (.pfw/skills)" : "global (~/.pfw/skills)"
      let symlinkLocation = useWorkspace ? "workspace" : "global"
      print("Skills stored in \(storageLocation)")
      print("Creating \(symlinkLocation) symlinks for selected AI tools...")

      let fileManager = FileManager.default

      for tool in selectedTools {
        let toolSkillsDir = tool.symlinkPath(workspace: useWorkspace)
        let expandedToolSkillsDir = URL(fileURLWithPath: NSString(string: toolSkillsDir.path).expandingTildeInPath)

        do {
          // Create the tool's skills directory if it doesn't exist
          try fileManager.createDirectory(atPath: expandedToolSkillsDir.path, withIntermediateDirectories: true)

          // Get all skill folders from .pfw/skills
          let skillFolders = try fileManager.contentsOfDirectory(atPath: expandedInstallURL.path)

          for skill in skillFolders {
            let skillPath = expandedInstallURL.appendingPathComponent(skill).path

            // Skip if skillPath is not a directory (e.g., .DS_Store)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: skillPath) {
              fileManager.fileExists(atPath: skillPath, isDirectory: &isDirectory)
            }

            guard isDirectory.boolValue else { continue }

            let symlinkPath = expandedToolSkillsDir.appendingPathComponent(skill).path
            let targetPath = skillPath
            let symlinkURL = URL(fileURLWithPath: symlinkPath)
            let targetURL = URL(fileURLWithPath: targetPath)

            do {
              // Remove existing symlink or directory if present
              if fileManager.fileExists(atPath: symlinkPath) {
                try fileManager.removeItem(atPath: symlinkPath)
              }
              // Create individual skill symlink
              try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: targetURL)
            } catch {
              print("✗ \(tool.rawValue)/\(skill): Failed to create symlink - \(error.localizedDescription)")
              failedSymlinks.append(tool)
            }
          }

          if !failedSymlinks.contains(tool) {
            let arrow = local ? "→ .pfw/skills/{...}" : "→ ~/.pfw/skills/{...}"
            print("✓ \(tool.rawValue): \(toolSkillsDir.path) \(arrow)")
          }
        } catch {
          print("✗ \(tool.rawValue): Failed to create skills directory - \(error.localizedDescription)")
          failedSymlinks.append(tool)
        }
      }
    }

    print("")
    if failedSymlinks.isEmpty {
      print("Installation complete!")
    } else {
      let failedNames = failedSymlinks.map(\.rawValue).joined(separator: ", ")
      print("Installation completed with errors. Failed symlinks: \(failedNames)")
      throw ExitCode.failure
    }
  }
}
