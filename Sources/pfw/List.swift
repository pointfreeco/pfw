import ArgumentParser
import Dependencies
import Foundation

struct List: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "List installed skills."
  )

  func run() throws {
    @Dependency(\.fileSystem) var fileSystem

    let centralSkillsURL = pfwDirectoryURL.appendingPathComponent("skills", isDirectory: true)

    guard fileSystem.fileExists(atPath: centralSkillsURL.path) else {
      print("No skills installed. Run `pfw install` first.")
      return
    }

    let skillDirectories = (try? fileSystem.contentsOfDirectory(at: centralSkillsURL)) ?? []
    let skills = skillDirectories
      .map { $0.lastPathComponent }
      .sorted()

    if skills.isEmpty {
      print("No skills installed. Run `pfw install` first.")
      return
    }

    print("Skills:")
    for skill in skills {
      print("  - \(skill)")
    }

    var installedTools: [(tool: Install.Tool, path: String)] = []
    for tool in Install.Tool.allCases {
      let toolPath = tool.defaultInstallPath
      guard fileSystem.fileExists(atPath: toolPath.path) else { continue }

      let contents = (try? fileSystem.contentsOfDirectory(at: toolPath)) ?? []
      let hasPfwSymlinks = contents.contains { url in
        url.lastPathComponent.hasPrefix("pfw-")
      }

      if hasPfwSymlinks {
        installedTools.append((tool: tool, path: toolPath.path))
      }
    }

    if !installedTools.isEmpty {
      print("")
      print("Installed for:")
      for (tool, path) in installedTools.sorted(by: { $0.tool.rawValue < $1.tool.rawValue }) {
        print("  \(tool.rawValue): \(path)")
      }
    }
  }
}
