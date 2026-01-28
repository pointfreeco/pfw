import ArgumentParser
import Dependencies
import Foundation
import NIO
import NIOHTTP1
import Synchronization

protocol Auth: Sendable {
  func start() async throws -> URL
  func waitForToken() async throws -> String
}

private enum AuthKey: DependencyKey {
  static var liveValue: any Auth {
    LocalAuthServer()
  }
}

extension DependencyValues {
  var auth: any Auth {
    get { self[AuthKey.self] }
    set { self[AuthKey.self] = newValue }
  }
}

actor UnimplementedAuthServer: Auth {
  struct UnimplementedError: Error {}
  func start() async throws -> URL {
    throw UnimplementedError()
  }

  func waitForToken() async throws -> String {
    throw UnimplementedError()
  }
}

actor LocalAuthServer: Auth {
  private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  private var channel: Channel?
  private var tokenContinuation: CheckedContinuation<String, Error>?
  private var hasShutdown = false

  func start() async throws -> URL {
    let bootstrap = ServerBootstrap(group: group)
      .serverChannelOption(ChannelOptions.backlog, value: 16)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
          channel.pipeline.addHandler(
            AuthHTTPHandler { result in
              Task { await self.finish(with: result) }
            }
          )
        }
      }
      .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

    let channel = try await wait(bootstrap.bind(host: "127.0.0.1", port: 0))
    self.channel = channel
    guard let port = channel.localAddress?.port else {
      throw ValidationError("Unable to determine callback port.")
    }
    return URL(string: "http://127.0.0.1:\(port)/callback")!
  }

  func waitForToken() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      tokenContinuation = continuation
    }
  }

  private func finish(with result: Result<String, Error>) {
    tokenContinuation?.resume(with: result)
    tokenContinuation = nil
    channel?.close(promise: nil)
    channel = nil
    shutdownIfNeeded()
  }

  private func shutdownIfNeeded() {
    guard !hasShutdown else { return }
    hasShutdown = true
    group.shutdownGracefully { _ in }
  }

  private func wait<T>(_ future: EventLoopFuture<T>) async throws -> T {
    try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<T, Error>) in
      future.whenComplete { result in
        switch result {
        case .success(let value):
          nonisolated(unsafe) let value = value
          continuation.resume(returning: value)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

private final class AuthHTTPHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart

  private let onResult: @Sendable (Result<String, Error>) -> Void
  private var requestHead: HTTPRequestHead?

  init(onResult: @escaping @Sendable (Result<String, Error>) -> Void) {
    self.onResult = onResult
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let part = unwrapInboundIn(data)
    switch part {
    case .head(let head):
      requestHead = head
    case .body:
      break
    case .end:
      guard let head = requestHead else { return }
      if let token = Self.token(from: head.uri) {
        respond(context: context, success: true)
        onResult(.success(token))
      } else {
        respond(context: context, success: false)
        onResult(.failure(ValidationError("Missing token in redirect.")))
      }
    }
  }

  private func respond(context: ChannelHandlerContext, success: Bool) {
    let message =
      success
      ? "You can return to the terminal. Login complete."
      : "Login failed. Please return to the terminal."
    let body = "<html><body><p>\(message)</p></body></html>"
    var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
    buffer.writeString(body)
    let head = HTTPResponseHead(
      version: .http1_1,
      status: .ok,
      headers: HTTPHeaders([
        ("Content-Type", "text/html; charset=utf-8"),
        ("Content-Length", "\(body.utf8.count)"),
        ("Connection", "close"),
      ])
    )
    context.write(wrapOutboundOut(.head(head)), promise: nil)
    context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
    context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    context.close(promise: nil)
  }

  private static func token(from uri: String) -> String? {
    guard let components = URLComponents(string: "http://localhost\(uri)"),
          let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
          !token.isEmpty
    else { return nil }
    return token
  }
}
