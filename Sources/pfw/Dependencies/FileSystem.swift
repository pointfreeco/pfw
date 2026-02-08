import Dependencies
import Foundation
import ZIPFoundation

protocol FileSystem: Sendable {
  var homeDirectoryForCurrentUser: URL { get }
  var currentDirectoryPath: String { get }
  static var temporaryDirectory: URL { get }
  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws
  func removeItem(at url: URL) throws
  func fileExists(atPath path: String) -> Bool
  func write(_ data: Data, to url: URL) throws
  func data(at url: URL) throws -> Data
  func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws
  func moveItem(at srcURL: URL, to dstURL: URL) throws
  func contentsOfDirectory(at url: URL) throws -> [URL]
  func unzipItem(at sourceURL: URL, to destinationURL: URL) throws
}

extension FileManager: FileSystem {
  func contentsOfDirectory(at url: URL) throws -> [URL] {
    try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
  }

  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
    try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
  }

  static var temporaryDirectory: URL {
    URL.temporaryDirectory
  }

  func write(_ data: Data, to url: URL) throws {
    try data.write(to: url)
  }

  func data(at url: URL) throws -> Data {
    try Data(contentsOf: url)
  }

  func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
    try unzipItem(
      at: sourceURL,
      to: destinationURL,
      skipCRC32: false,
      allowUncontainedSymlinks: false,
      progress: nil,
      pathEncoding: nil
    )
  }
}

enum FileSystemKey: DependencyKey {
  static var liveValue: any FileSystem { FileManager.default }
}

extension DependencyValues {
  var fileSystem: any FileSystem {
    get { self[FileSystemKey.self] }
    set { self[FileSystemKey.self] = newValue }
  }
}
