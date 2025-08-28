# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chatty is a native macOS MCP (Model Context Protocol) client with assistant capabilities. The app provides a SwiftUI interface for connecting to MCP servers, discovering tools, and executing assistant tasks through a managed context system.

## Build Commands

```bash
# Build the Swift package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter TestClassName

# Build for release
swift build -c release

# Clean build artifacts
swift build --clean

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture

The codebase follows a three-layer architecture:

1. **MCP Layer** (`Sources/MCPClient/`): Handles JSON-RPC protocol, transport (stdio/SSE), and server communication
2. **Assistant Layer** (`Sources/Assistant/`): Manages task queuing, context windows, subagent allocation, and backpressure
3. **UI Layer** (`Sources/ChattyApp/`): SwiftUI views with optional TCA stores for state management

Key architectural decisions:
- Single-process model for App Store sandbox compliance
- Token-based context management with sliding windows
- Stdio transport for local MCP servers, SSE for remote
- Request/response correlation via numeric IDs in JSON-RPC

## Development Workflow

Follow the fix_plan.md for the implementation order of tasks. Each task has specific acceptance criteria and file targets. The plan follows a bottom-up approach: core MCP protocol → assistant engine → UI integration.

## Testing Strategy

- Unit tests for MCP protocol encoding/decoding
- Mock transports for testing without real servers
- Integration tests for assistant task processing
- UI tests for critical user flows

## MCP Protocol Implementation

The client implements JSON-RPC 2.0 with:
- Initialize handshake for capability discovery
- Tool invocation with parameter marshaling
- Notification handling (no response expected)
- Batch request support
- Exponential backoff on transport failures

## Context Management

The assistant maintains context budgets:
- Default 4K tokens per subagent
- Sliding window keeps recent 75% of context
- Tool results truncated at 8K characters
- Automatic summarization on overflow