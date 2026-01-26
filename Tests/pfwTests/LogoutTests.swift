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
  @MainActor struct LogoutTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

    @Test(
      .dependencies { _ in 
        var command = try #require(try PFW.parseAsRoot(["login"]) as? AsyncParsableCommand)
        try await command.run()
      }
    )
    func logout() async throws {
      try await assertCommand(["logout"]) {
        """
        Removed token at /Users/blob/.pfw/token.
        """
      }
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .pfw/
              machine "00000000-0000-0000-0000-000000000000"
        tmp/
        """
      }
    }

    @Test
    func logout_NotLoggedIn() async throws {
      try await assertCommand(["logout"]) {
        """
        No token found.
        """
      }
    }
  }
}
