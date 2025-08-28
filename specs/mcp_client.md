# MCP Client

## Transport Layer
- **StdioTransport**: Process-based JSON-RPC over stdin/stdout
- **SSETransport**: Server-sent events for web-based MCP servers
- **Message framing**: Length-prefixed JSON with newline delimiters

## Protocol Implementation
- JSON-RPC 2.0 compliant
- Request/response correlation via numeric IDs
- Notification handling (no response expected)
- Batch request support

## Capability Discovery
- `initialize` handshake with client info
- Server capabilities response parsing
- Tool manifest caching
- Resource availability tracking

## Error Handling
- Transport failures: Exponential backoff reconnect
- Protocol errors: Surface to assistant with fallback
- Timeout management: 30s default, configurable per tool

## Authentication
- Bearer token for SSE endpoints
- Environment variable injection for stdio
- Keychain integration for credential storage

## Message Types
```swift
protocol MCPMessage: Codable {
    var jsonrpc: String { get }
    var id: Int? { get }
}
```