import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @MainActor
  @Suite
  struct ConfigDirectoryTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
        $0.environment = TestEnvironment([
            "PFW_HOME": "/root/custom",
            "XDG_CONFIG_HOME": "/root/.xdg"
        ])
      }
    )
    func configDirUsesPfwHomeWhenPresent() throws {
      try save(token: "deadbeef")
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          custom/
            token "deadbeef"
        tmp/
        """
      }
    }

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
        $0.environment = TestEnvironment(["XDG_CONFIG_HOME": "/root/.xdg"])
      }
    )
    func configDirUsesXdgWhenPresent() throws {
      try save(token: "deadbeef")
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          .xdg/
            pfw/
              token "deadbeef"
        tmp/
        """
      }
    }

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
      }
    )
    func configDirFallsBackToLegacy() throws {
      try save(token: "deadbeef")
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          .pfw/
            token "deadbeef"
        tmp/
        """
      }
    }
  }
}
