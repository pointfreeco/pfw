import ArgumentParser
import Foundation

@main
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct PFW: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "pfw",
    abstract: "CLI for managing Point-Free Way skills.",
    subcommands: [
      Login.self,
      Logout.self,
      Status.self,
      Install.self,
    ]
  )
}
