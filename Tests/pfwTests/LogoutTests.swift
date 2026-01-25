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
  struct LogoutTests {
    @Dependency(\.fileSystem) var fileSystem
    var inMemoryFileSystem: InMemoryFileSystem {
      fileSystem as! InMemoryFileSystem
    }

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
              machine (36 bytes)
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
