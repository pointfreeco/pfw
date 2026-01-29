import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@testable import pfw

extension BaseSuite {
  @Suite @MainActor struct ListTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

    @Test func noSkillsDirectory() async throws {
      try await assertCommand(["list"]) {
        """
        No skills installed. Run `pfw install` first.
        """
      }
    }

    @Test func emptySkillsDirectory() async throws {
      try fileSystem.createDirectory(
        at: URL(fileURLWithPath: "/Users/blob/.pfw/skills"),
        withIntermediateDirectories: true
      )
      try await assertCommand(["list"]) {
        """
        No skills installed. Run `pfw install` first.
        """
      }
    }

    @Test func skillsInstalledNoTools() async throws {
      let skillsURL = URL(fileURLWithPath: "/Users/blob/.pfw/skills")
      try fileSystem.createDirectory(at: skillsURL, withIntermediateDirectories: true)
      try fileSystem.createDirectory(
        at: skillsURL.appendingPathComponent("ComposableArchitecture"),
        withIntermediateDirectories: false
      )
      try fileSystem.createDirectory(
        at: skillsURL.appendingPathComponent("Dependencies"),
        withIntermediateDirectories: false
      )

      try await assertCommand(["list"]) {
        """
        Skills:
          - ComposableArchitecture
          - Dependencies
        """
      }
    }

    @Test func skillsInstalledWithTools() async throws {
      let skillsURL = URL(fileURLWithPath: "/Users/blob/.pfw/skills")
      try fileSystem.createDirectory(at: skillsURL, withIntermediateDirectories: true)
      try fileSystem.createDirectory(
        at: skillsURL.appendingPathComponent("ComposableArchitecture"),
        withIntermediateDirectories: false
      )
      try fileSystem.createDirectory(
        at: skillsURL.appendingPathComponent("Dependencies"),
        withIntermediateDirectories: false
      )

      let claudeSkillsURL = URL(fileURLWithPath: "/Users/blob/.claude/skills")
      try fileSystem.createDirectory(at: claudeSkillsURL, withIntermediateDirectories: true)
      try fileSystem.createSymbolicLink(
        at: claudeSkillsURL.appendingPathComponent("pfw-ComposableArchitecture"),
        withDestinationURL: skillsURL.appendingPathComponent("ComposableArchitecture")
      )
      try fileSystem.createSymbolicLink(
        at: claudeSkillsURL.appendingPathComponent("pfw-Dependencies"),
        withDestinationURL: skillsURL.appendingPathComponent("Dependencies")
      )

      let cursorSkillsURL = URL(fileURLWithPath: "/Users/blob/.cursor/skills")
      try fileSystem.createDirectory(at: cursorSkillsURL, withIntermediateDirectories: true)
      try fileSystem.createSymbolicLink(
        at: cursorSkillsURL.appendingPathComponent("pfw-ComposableArchitecture"),
        withDestinationURL: skillsURL.appendingPathComponent("ComposableArchitecture")
      )

      try await assertCommand(["list"]) {
        """
        Skills:
          - ComposableArchitecture
          - Dependencies

        Installed for:
          claude: /Users/blob/.claude/skills
          cursor: /Users/blob/.cursor/skills
        """
      }
    }
  }
}
