import Dependencies
import SnapshotTesting
import Testing

@Suite(
  .snapshots(record: .missing),
  .dependencies {
    $0.uuid = .incrementing
  }
)
struct BaseSuite {}
