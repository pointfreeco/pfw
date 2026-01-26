import Dependencies
import SnapshotTesting
import Testing

@Suite(
  .serialized,
  .snapshots(record: .missing),
  .dependencies {
    $0.uuid = .incrementing
  }
)
@MainActor
struct BaseSuite {}
