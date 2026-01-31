import Dependencies
import SnapshotTesting
import Testing

@testable import pfw

@Suite(
  .serialized,
  .snapshots(record: .missing),
  .dependencies {
    $0.uuid = .incrementing
    $0.auth = InMemoryAuth()
    $0.fileSystem = InMemoryFileSystem()
    $0.openInBrowser = MockOpenInBrowser()
    $0.pointFreeServer = InMemoryPointFreeServer(result: .failure(.invalidResponse))
    $0.gitHub = InMemoryGitHub(tags: [])
    $0.whoAmI = TestWhoAmI("blob")
  }
)
@MainActor
struct BaseSuite {}
