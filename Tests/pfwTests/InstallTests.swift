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
  @MainActor struct InstallTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

    @Test func noToolSpecified() async throws {
      await assertCommandThrows(["install"]) {
        """
        Provide either --tool or --path.
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

    @Test(
      .dependencies {
        try save(token: "expired-deadbeef")
        $0.pointFreeServer = try InMemoryPointFreeServer(
          result: .success(
            [
              URL(filePath: "/skills/ComposableArchitecture/SKILL.md"): Data(
                """
                # Composable Architecture
                """.utf8
              )
            ].toData
          )
        )
      }
    ) func expiredToken() async throws {
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .pfw/
              token "expired-deadbeef"
        tmp/
        """
      }
      try await assertCommand(["install", "--tool", "codex"]) {
        """
        Installed skills for codex into /Users/blob/.codex/skills/the-point-free-way
        """
      }
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .codex/
              skills/
                the-point-free-way/
                  skills/
                    ComposableArchitecture/
                      SKILL.md "# Composable Architecture"
            .pfw/
              machine "00000000-0000-0000-0000-000000000000"
              token "expired-deadbeef"
        tmp/
          00000000-0000-0000-0000-000000000001 (94 bytes)
        """
      }
    }

    @Suite(
      .dependencies {
        var command = try #require(try PFW.parseAsRoot(["login"]) as? AsyncParsableCommand)
        try await command.run()
        $0.pointFreeServer = try InMemoryPointFreeServer(
          result: .success(
            [
              URL(filePath: "/skills/ComposableArchitecture/SKILL.md"): Data(
                """
                # Composable Architecture
                """.utf8
              ),
              URL(filePath: "/skills/ComposableArchitecture/references/navigation.md"): Data(
                """
                # Navigation
                """.utf8
              ),
              URL(filePath: "/skills/SQLiteData/SKILL.md"): Data(
                """
                # SQLiteData
                """.utf8
              ),
            ].toData
          )
        )
      }
    )
    @MainActor struct LoggedIn {
      @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

      @Test func codex() async throws {
        try await assertCommand(["install", "--tool", "codex"]) {
          """
          Installed skills for codex into /Users/blob/.codex/skills/the-point-free-way
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  the-point-free-way/
                    skills/
                      ComposableArchitecture/
                        SKILL.md "# Composable Architecture"
                        references/
                          navigation.md "# Navigation"
                      SQLiteData/
                        SKILL.md "# SQLiteData"
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                token "deadbeef"
          tmp/
            00000000-0000-0000-0000-000000000002 (245 bytes)
          """
        }
      }

      @Test func claude() async throws {
        try await assertCommand(["install", "--tool", "claude"]) {
          """
          Installed skills for claude into /Users/blob/.claude/skills/the-point-free-way
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .claude/
                skills/
                  the-point-free-way/
                    skills/
                      ComposableArchitecture/
                        SKILL.md "# Composable Architecture"
                        references/
                          navigation.md "# Navigation"
                      SQLiteData/
                        SKILL.md "# SQLiteData"
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                token "deadbeef"
          tmp/
            00000000-0000-0000-0000-000000000002 (245 bytes)
          """
        }
      }

      // NB: This test shows a problem with using the '--path' option that we need to fix.
//      @Test(
//        .dependencies {
//          try $0.fileSystem.createDirectory(
//            at: URL(filePath: "/Users/blob/.copilot/skills"),
//            withIntermediateDirectories: true
//          )
//          try $0.fileSystem.write(
//            Data("Hello".utf8),
//            to: URL(filePath: "/Users/blob/.copilot/skills/dont-delete.md")
//          )
//        }
//      )
//      func customPath() async throws {
//        try await assertCommand(["install", "--path", "/Users/blob/.copilot/skills"]) {
//          """
//          Installed skills into /Users/blob/.copilot/skills
//          """
//        }
//        assertInlineSnapshot(of: fileSystem, as: .description)
//      }
    }
  }
}

extension [URL: Data] {
  var toData: Data {
    get throws {
      try JSONEncoder().encode(self)
    }
  }
}
