# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chatty is a native macOS MCP (Model Context Protocol) client with assistant capabilities. The app provides a SwiftUI interface for connecting to MCP servers, discovering tools, and executing assistant tasks through a managed context system.

## Current Project State

The project is currently in early development stage with:
- **Xcode Project**: Basic SwiftUI app structure initialized (Chatty.xcodeproj)
- **UI Layer**: Initial ContentView and SwiftData model setup
- **Build System**: Using Xcode project (Swift Package Manager to be added)
- **Architecture Specs**: Detailed specifications in `specs/` directory
- **Task Plan**: Implementation roadmap in `fix_plan.md` with 12 tasks defined

### Pending Implementation
- Swift Package Manager structure (Package.swift)
- MCP client implementation (`Sources/MCPClient/`)
- Assistant engine (`Sources/Assistant/`)
- Full SwiftUI interface (`Sources/ChattyApp/`)
- Test suites (`Tests/`)

## ICYMI

- Ignore the .tmp dir, use only as a mv target instead of rm
- Files should end with a single newline
- Commits should be frequent for easy rollback
- Never add co-author information or Claude attribution

## Build Commands

### Current (Xcode)
```bash
# Open in Xcode
open Chatty/Chatty.xcodeproj

# Build from command line
xcodebuild -project Chatty/Chatty.xcodeproj -scheme Chatty build

# Run from command line
xcodebuild -project Chatty/Chatty.xcodeproj -scheme Chatty -destination 'platform=macOS' build-for-testing
```

### Future (Swift Package Manager)
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
```

## Architecture

The codebase will follow a three-layer architecture:

1. **MCP Layer** (`Sources/MCPClient/`): Handles JSON-RPC protocol, transport (stdio/SSE), and server communication
2. **Assistant Layer** (`Sources/Assistant/`): Manages task queuing, context windows, subagent allocation, and backpressure
3. **UI Layer** (`Sources/ChattyApp/`): SwiftUI views with optional TCA stores for state management

Key architectural decisions:

- Single-process model for App Store sandbox compliance
- Token-based context management with sliding windows
- Stdio transport for local MCP servers, SSE for remote
- Request/response correlation via numeric IDs in JSON-RPC
- Ralph methodology for development iterations

## Development Workflow

### Ralph Loop
The project uses automated Ralph iterations via `scripts/run_iteration.sh`:
1. Read specs and fix plan
2. Select next unblocked task
3. Make minimal, compilable changes
4. Validate with Swift toolchain
5. Commit on green builds only

### Task Implementation Order
Follow the fix_plan.md for the implementation order of tasks. The plan follows a bottom-up approach:
1. Project setup and Swift Package Manager
2. Core MCP protocol implementation
3. Assistant engine development
4. UI integration
5. Testing and release preparation

## Testing Strategy

- Unit tests for MCP protocol encoding/decoding
- Mock transports for testing without real servers
- Integration tests for assistant task processing
- UI tests for critical user flows
- Target 70% code coverage

## MCP Protocol Implementation

The client will implement JSON-RPC 2.0 with:

- Initialize handshake for capability discovery
- Tool invocation with parameter marshaling
- Notification handling (no response expected)
- Batch request support
- Exponential backoff on transport failures

## Context Management

The assistant will maintain context budgets:

- Default 4K tokens per subagent
- Sliding window keeps recent 75% of context
- Tool results truncated at 8K characters
- Automatic summarization on overflow
