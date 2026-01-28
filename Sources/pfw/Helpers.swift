import Foundation

extension URL {
  static var baseURL: URL {
    #if DEBUG
      return URL(string: "http://localhost:8080")!
    #else
      return URL(string: "https://www.pointfree.co")!
    #endif
  }
}
