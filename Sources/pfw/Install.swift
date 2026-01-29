import ArgumentParser
import Dependencies
import Foundation

struct Install: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Download and install Point-Free Way skills."
  )

  enum Tool: String, CaseIterable, ExpressibleByArgument {
    case agents
    case amp
    case antigravity
    case claude
    case codex
    case copilot
    case cursor
    case droid
    case gemini
    case kiro
    case kimi
    case opencode

    var defaultInstallPath: URL {
      @Dependency(\.fileSystem) var fileSystem
      let home = fileSystem.homeDirectoryForCurrentUser

      switch self {
      case .amp:
        return
          home
          .appending(path: ".agents")
          .appending(path: "skills")
      case .antigravity:
        return
          home
          .appending(path: ".gemini")
          .appending(path: "antigravity")
          .appending(path: "global_skills")
      case .droid:
        return
          home
          .appending(path: ".factory")
          .appending(path: "skills")
      case .opencode:
        return
          home
          .appending(path: ".config")
          .appending(path: "opencode")
          .appending(path: "skills")
      default:
        return
          home
          .appending(path: ".\(rawValue)")
          .appending(path: "skills")
      }
    }
  }

  @Option(
    name: .customLong("tool"),
    help: """
      Which AI tool to install skills for. \
      Options: \(Tool.allCases.map(\.rawValue).joined(separator: ", ")).
      """
  )
  var tools: [Tool] = []

  @Option(
    name: .customLong("path"),
    help: "Directory to install skills into."
  )
  var paths: [String] = []

  @Flag(
    name: .shortAndLong,
    help: "Ignore the local SHA and always download."
  )
  var force = false

  func run() async throws {
    try await install(shouldRetryAfterLogin: true)
  }

  private func install(shouldRetryAfterLogin: Bool) async throws {
    @Dependency(\.pointFreeServer) var pointFreeServer
    @Dependency(\.fileSystem) var fileSystem
    @Dependency(\.uuid) var uuid
    @Dependency(\.whoAmI) var whoAmI

    let installTargets: [(tool: Tool?, path: String)]
    if tools.isEmpty, paths.isEmpty {
      let detectedTools = Tool.allCases.filter { tool in
        fileSystem.fileExists(atPath: tool.defaultInstallPath.path)
      }
      guard !detectedTools.isEmpty else {
        throw ValidationError("No tools detected in home directory. Provide --tool or --path.")
      }
      installTargets = detectedTools.map { (tool: $0, path: $0.defaultInstallPath.path) }
    } else {
      installTargets =
        tools.map { (tool: $0, path: $0.defaultInstallPath.path) }
        + paths.map { (tool: nil, path: $0) }
    }

    let token = try loadToken()
    let machine = try machine()
    let sha = force ? nil : loadSHA()
    let data: Data
    do {
      let response = try await pointFreeServer.downloadSkills(
        token: token,
        machine: machine,
        whoami: whoAmI(),
        sha: sha
      )
      switch response {
      case .data(let downloadedData, let etag):
        data = downloadedData
        try save(sha: etag)
      case .notModified:
        print("Skills already up to date.")
        return
      }
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
      case .missingEtag:
        print("Server response error. Contact support@pointfree.co if problem persists.")
        return
      case .invalidResponse:
        print("Unexpected response from server.")
        return
      }
    }

    let zipURL = type(of: fileSystem).temporaryDirectory.appending(path: uuid().uuidString + ".zip")
    try fileSystem.write(data, to: zipURL)

    let tempUnzipURL = type(of: fileSystem).temporaryDirectory.appending(path: uuid().uuidString)
    try fileSystem.createDirectory(at: tempUnzipURL, withIntermediateDirectories: true)
    try fileSystem.unzipItem(at: zipURL, to: tempUnzipURL)

    let skillsSourceURL = tempUnzipURL.appendingPathComponent("skills")
    guard fileSystem.fileExists(atPath: skillsSourceURL.path)
    else {
      print("Could not unzip skills.")
      throw ExitCode.failure
    }

    let centralSkillsURL = pfwDirectoryURL.appendingPathComponent("skills", isDirectory: true)
    try? fileSystem.removeItem(at: centralSkillsURL)
    try fileSystem.createDirectory(at: centralSkillsURL, withIntermediateDirectories: true)

    let existingCentral = (try? fileSystem.contentsOfDirectory(at: centralSkillsURL)) ?? []
    for url in existingCentral where url.lastPathComponent.hasPrefix("pfw-") {
      try? fileSystem.removeItem(at: url)
    }

    let skillDirectories = (try? fileSystem.contentsOfDirectory(at: skillsSourceURL)) ?? []
    for directory in skillDirectories {
      let centralDestination = centralSkillsURL.appendingPathComponent(directory.lastPathComponent)
      try fileSystem.moveItem(at: directory, to: centralDestination)
    }

    for target in installTargets {
      let expandedPath: String
      if target.path.hasPrefix("~/") {
        expandedPath = fileSystem.homeDirectoryForCurrentUser.path + "/" + target.path.dropFirst(2)
      } else {
        expandedPath = target.path
      }
      let skillsURL = URL(fileURLWithPath: expandedPath)
      try fileSystem.createDirectory(at: skillsURL, withIntermediateDirectories: true)

      let existing = (try? fileSystem.contentsOfDirectory(at: skillsURL)) ?? []
      for url in existing
      where url.lastPathComponent.hasPrefix("pfw-")
        || url.lastPathComponent == "the-point-free-way"
      {
        try? fileSystem.removeItem(at: url)
      }

      let centralSkillDirectories =
        (try? fileSystem.contentsOfDirectory(at: centralSkillsURL)) ?? []
      for directory in centralSkillDirectories {
        let toolDestination = skillsURL.appendingPathComponent("pfw-\(directory.lastPathComponent)")
        try fileSystem.createSymbolicLink(at: toolDestination, withDestinationURL: directory)
      }
      if let tool = target.tool {
        print("Installed skills for \(tool.rawValue) into \(skillsURL.path)")
      } else {
        print("Installed skills into \(skillsURL.path)")
      }
    }

    try? fileSystem.removeItem(at: zipURL)
    try? fileSystem.removeItem(at: tempUnzipURL)
  }
}
