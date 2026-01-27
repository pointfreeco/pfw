import ArgumentParser
import Dependencies
import Foundation

func machine() throws -> UUID {
  @Dependency(\.fileSystem) var fileSystem
  @Dependency(\.uuid) var uuid
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  if let currentMachineData = try? Data(contentsOf: machineURL),
    let currentMachine = UUID(uuidString: String(decoding: currentMachineData, as: UTF8.self))
  {
    return currentMachine
  } else {
    try? fileSystem.removeItem(at: machineURL)
    let newMachine = uuid()
    try fileSystem.write(Data(newMachine.uuidString.utf8), to: machineURL)
    return newMachine
  }
}

var pfwDirectoryURL: URL {
  @Dependency(\.fileSystem) var fileSystem
  return fileSystem.homeDirectoryForCurrentUser
    .appendingPathComponent(".pfw", isDirectory: true)
}

let machineURL = pfwDirectoryURL.appendingPathComponent("machine")
let tokenURL = pfwDirectoryURL.appendingPathComponent("token")
let shaURL = pfwDirectoryURL.appendingPathComponent("sha")

func save(token: String) throws {
  @Dependency(\.fileSystem) var fileSystem
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  try fileSystem.write(
    Data(token.trimmingCharacters(in: .whitespacesAndNewlines).utf8),
    to: tokenURL
  )
}

func loadToken() throws -> String {
  @Dependency(\.fileSystem) var fileSystem
  guard fileSystem.fileExists(atPath: tokenURL.path) else {
    throw ValidationError("No token found. Run `pfw login` first.")
  }
  return try String(decoding: fileSystem.data(at: tokenURL), as: UTF8.self)
}

func loadSHA() -> String? {
  @Dependency(\.fileSystem) var fileSystem
  guard let data = try? fileSystem.data(at: shaURL)
  else {
    return nil
  }
  return String(decoding: data, as: UTF8.self)
    .trimmingCharacters(in: .whitespacesAndNewlines)
}

func save(sha: String) throws {
  @Dependency(\.fileSystem) var fileSystem
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  try fileSystem.write(
    Data(sha.trimmingCharacters(in: .whitespacesAndNewlines).utf8),
    to: shaURL
  )
}
