import ArgumentParser
import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @Suite(
    .dependencies {
      $0.auth = InMemoryAuth(
        redirectURL: URL(string: "http://localhost:1234/callback"),
        token: "deadbeef"
      )
    }
  )
  struct InstallTests {
    @Test func noToolSpecified() async throws {
      await assertCommandThrows(["install"]) {
        """
        Missing expected argument '--tool <tool>'
        """
      }
    }

    @Test func loggedOut() async throws {
      await assertCommandThrows(["install", "--tool", "codex"]) {
        """
        No token found. Run `pfw login` first.
        """
      }
    }

    @Suite(
      .dependencies { _ in
        var command = try #require(try PFW.parseAsRoot(["login"]) as? AsyncParsableCommand)
        try await command.run()
      }
    )
    struct LoggedIn {
      var fileSystem: InMemoryFileSystem {
        @Dependency(\.fileSystem) var fileSystem
        return fileSystem as! InMemoryFileSystem
      }
      
      @Test func codex() async throws {
        try await assertCommand(["install", "--tool", "codex"])
        assertInlineSnapshot(of: fileSystem, as: .description)
      }
    }
  }
}
