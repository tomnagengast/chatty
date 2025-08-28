SYSTEM
You are the single iteration of the Ralph loop.

STACK (verbatim contents follow):

---FILE: specs/architecture.md---
# Architecture

## Overview
Native macOS app using SwiftUI + AppKit for MCP client with assistant capabilities.

## Core Components
- **MCPClient**: Protocol transport (stdio/SSE), message routing, capability discovery
- **AssistantEngine**: Task queue, subagent allocation, context management, backpressure control
- **UILayer**: SwiftUI views, TCA stores (optional), native macOS integration
- **ToolBridge**: MCP tool invocation, parameter marshaling, result handling

## Data Flow
- User input → AssistantEngine → Task decomposition
- Task → MCPClient → Tool invocation → Response
- Response → AssistantEngine → UI update

## Key Constraints
- Sandboxed execution (App Store compatible)
- Single process model (no spawning)
- Memory-bound context windows
- Rate-limited MCP server interactions

## Dependencies
- macOS 14.0+ (latest Swift concurrency)
- Swift Package Manager
- No external binaries (sandbox compliance)

---FILE: specs/assistant_loop.md---
# Assistant Loop

## Task Queue
- FIFO processing with priority override
- Task decomposition into atomic operations
- Dependency graph resolution
- Cancellation support

## Subagent Allocation
- Single active subagent per task
- Context budget per subagent (4K tokens default)
- Tool whitelist per subagent type
- Result aggregation and handoff

## Backpressure Management
- Token counting before submission
- Context window sliding (keep recent 75%)
- Tool result truncation at 8K chars
- Pause queue when approaching limits

## Execution Flow
```
1. Parse user intent → Task
2. Allocate subagent with context slice
3. Execute tool calls via MCPClient
4. Collect results → Update context
5. Check completion criteria
6. Loop or hand off to next task
```

## Context Management
- System prompt (immutable)
- Conversation history (sliding window)
- Tool results (most recent N)
- Task state (current + pending)

## Error Recovery
- Tool failure: Retry with backoff or skip
- Context overflow: Summarize and continue
- Subagent timeout: Cancel and report

---FILE: specs/mcp_client.md---
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

---FILE: specs/ui.md---
# UI Specification

## Main Window
- **ChatView**: Message list, input field, send button
- **SidebarView**: Server list, tool catalog, session history
- **StatusBar**: Connection state, token usage, active task

## Chat Interface
- Markdown rendering for assistant responses
- Code syntax highlighting
- Tool invocation indicators (spinner, progress)
- Collapsible tool results

## Server Management
- Add/edit/remove MCP servers
- Test connection button
- Capability viewer (available tools/resources)
- Start/stop server processes

## Navigation
- Tab-based (Chat, Servers, Settings)
- Keyboard shortcuts (⌘N new chat, ⌘K command palette)
- Deep linking to specific tools/servers

## State Management
- TCA store for reactive updates (optional)
- @Observable models for simpler state
- UserDefaults for preferences
- CloudKit for session sync (future)

## Visual Design
- Native macOS styling (SF Symbols, system colors)
- Dark/light mode support
- Compact/regular size classes
- Accessibility labels throughout

---FILE: fix_plan.md---
# Fix Plan

## Tasks

### 0. create-package-swift ✅
- **id**: create-package-swift
- **rationale**: Create minimal Package.swift file to enable Swift Package Manager builds
- **acceptance**: 
  - Package.swift exists with valid syntax ✅
  - Defines executable product named "Chatty" ✅
  - Sets macOS 14.0 platform minimum ✅
- **files**: Package.swift
- **est_effort**: XS
- **dependencies**: []
- **status**: COMPLETED

### 1. project-setup
- **id**: project-setup
- **rationale**: Complete Swift package structure with source directories and initial app file
- **acceptance**: 
  - Sources/ChattyApp directory exists
  - Main.swift compiles with `swift build`
  - Basic executable runs
- **files**: Sources/ChattyApp/Main.swift, .gitignore
- **est_effort**: XS
- **dependencies**: [create-package-swift]

### 2. mcp-models
- **id**: mcp-models  
- **rationale**: Define core MCP protocol types for JSON-RPC messaging
- **acceptance**:
  - Codable models for Request, Response, Error
  - Unit tests for JSON encoding/decoding
  - No compiler warnings
- **files**: Sources/MCPClient/Models/, Tests/MCPClientTests/ModelsTests.swift
- **est_effort**: S
- **dependencies**: [project-setup]

### 3. mcp-transport-stdio
- **id**: mcp-transport-stdio
- **rationale**: Implement process-based transport for local MCP servers
- **acceptance**:
  - Can spawn and communicate with echo server
  - Handles process lifecycle (start/stop)
  - Tests pass with mock process
- **files**: Sources/MCPClient/Transport/StdioTransport.swift
- **est_effort**: M
- **dependencies**: [mcp-models]

### 4. mcp-client-core
- **id**: mcp-client-core
- **rationale**: Build request/response correlation and capability discovery
- **acceptance**:
  - Initialize handshake completes
  - Tool list retrieved and cached
  - Concurrent requests handled correctly
- **files**: Sources/MCPClient/MCPClient.swift, Sources/MCPClient/MCPClientProtocol.swift
- **est_effort**: M
- **dependencies**: [mcp-transport-stdio]

### 5. assistant-task-queue
- **id**: assistant-task-queue
- **rationale**: Create task processing pipeline for assistant operations
- **acceptance**:
  - Tasks enqueue and dequeue in order
  - Cancellation works mid-execution
  - Priority override functions
- **files**: Sources/Assistant/TaskQueue.swift, Sources/Assistant/Task.swift
- **est_effort**: S
- **dependencies**: [mcp-client-core]

### 6. assistant-context-manager
- **id**: assistant-context-manager
- **rationale**: Manage token budgets and context windows for subagents
- **acceptance**:
  - Token counting accurate within 5%
  - Sliding window maintains recent context
  - Truncation preserves semantics
- **files**: Sources/Assistant/ContextManager.swift
- **est_effort**: S
- **dependencies**: [assistant-task-queue]

### 7. ui-chat-view
- **id**: ui-chat-view
- **rationale**: Build primary conversation interface with message rendering
- **acceptance**:
  - Messages display with proper formatting
  - Input field sends on return
  - Scrolls to bottom on new message
- **files**: Sources/ChattyApp/Views/ChatView.swift, Sources/ChattyApp/Models/Message.swift
- **est_effort**: S
- **dependencies**: [project-setup]

### 8. ui-server-manager
- **id**: ui-server-manager
- **rationale**: Create server configuration and connection management UI
- **acceptance**:
  - Can add/edit server configs
  - Connection status updates live
  - Settings persist across launches
- **files**: Sources/ChattyApp/Views/ServerListView.swift, Sources/ChattyApp/Models/ServerConfig.swift
- **est_effort**: S
- **dependencies**: [ui-chat-view, mcp-client-core]

### 9. assistant-integration
- **id**: assistant-integration
- **rationale**: Wire assistant engine to UI and MCP client
- **acceptance**:
  - User messages trigger assistant processing
  - Tool results display in chat
  - Errors surface gracefully
- **files**: Sources/Assistant/AssistantEngine.swift, Sources/ChattyApp/ViewModels/ChatViewModel.swift
- **est_effort**: M
- **dependencies**: [assistant-context-manager, ui-chat-view, ui-server-manager]

### 10. app-persistence
- **id**: app-persistence
- **rationale**: Save server configs and chat history locally
- **acceptance**:
  - Servers persist across app restarts
  - Chat history survives crashes
  - Can export/import configs
- **files**: Sources/ChattyApp/Storage/PersistenceController.swift
- **est_effort**: S
- **dependencies**: [assistant-integration]

### 11. testing-suite
- **id**: testing-suite
- **rationale**: Comprehensive test coverage for critical paths
- **acceptance**:
  - 70% code coverage
  - All public APIs have tests
  - CI runs tests on commit
- **files**: Tests/, .github/workflows/test.yml
- **est_effort**: S
- **dependencies**: [app-persistence]

### 12. release-prep
- **id**: release-prep
- **rationale**: Package app for distribution with proper signing
- **acceptance**:
  - Archive builds successfully
  - Notarization passes
  - README documents setup
- **files**: README.md, Info.plist, Entitlements.plist
- **est_effort**: XS
- **dependencies**: [testing-suite]

SIGNS (binding rules from CLAUDE.md):

---FILE: CLAUDE.md---
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


INSTRUCTIONS
- Follow SIGNS strictly (no placeholders; search before write; minimal compiling diffs).
- Select the first unblocked task from fix_plan.md.
- You may use tools to read files, search the codebase, and write code as needed.
- After completing your implementation, return STRICT JSON with: selected_task_id, why_this_task, plan, diffs[], validator{}, fix_plan_updates[].
- Diffs must be unified patches that apply cleanly with `git apply`.

OUTPUT
After using any necessary tools to complete the task, return ONLY the JSON object (no fences, no extra text) as your final message.
