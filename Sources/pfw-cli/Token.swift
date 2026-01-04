import ArgumentParser
import Foundation

let directoryURL: URL = {
  let home = FileManager.default.homeDirectoryForCurrentUser
  return home.appendingPathComponent(".pfw", isDirectory: true)
}()

let storeURL: URL = directoryURL.appendingPathComponent("token")

func save(token: String) throws {
  try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
  try token.trimmingCharacters(in: .whitespacesAndNewlines)
    .write(to: storeURL, atomically: true, encoding: .utf8)
}

func loadToken() throws -> String {
  guard FileManager.default.fileExists(atPath: storeURL.path) else {
    throw ValidationError("No token found. Run `pfw login` first.")
  }
  return try String(contentsOf: storeURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
}
