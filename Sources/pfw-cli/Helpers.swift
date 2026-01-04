import Foundation

extension URL {
  static var baseURL: String {
    #if DEBUG
    return "http://localhost:8080"
    #else
    return "https://www.pointfree.co"
    #endif
  }
}
