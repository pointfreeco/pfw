import ArgumentParser
import Foundation

func machine() throws -> UUID {
  try FileManager.default.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  if
    let currentMachineData = try? Data(contentsOf: machineURL),
    let currentMachine = UUID(uuidString: String(decoding: currentMachineData, as: UTF8.self))
  {
    return currentMachine
  } else {
    try? FileManager.default.removeItem(at: machineURL)
    let newMachine = UUID()
    try newMachine.uuidString.write(to: machineURL, atomically: true, encoding: .utf8)
    return newMachine
  }

}

let pfwDirectoryURL: URL = {
  let home = FileManager.default.homeDirectoryForCurrentUser
  return home.appendingPathComponent(".pfw", isDirectory: true)
}()

let machineURL = pfwDirectoryURL.appendingPathComponent("machine")
let tokenURL = pfwDirectoryURL.appendingPathComponent("token")

func save(token: String) throws {
  try FileManager.default.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  try token.trimmingCharacters(in: .whitespacesAndNewlines)
    .write(to: tokenURL, atomically: true, encoding: .utf8)
}

func loadToken() throws -> String {
  guard FileManager.default.fileExists(atPath: tokenURL.path) else {
    throw ValidationError("No token found. Run `pfw login` first.")
  }
  return try String(contentsOf: tokenURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
}
