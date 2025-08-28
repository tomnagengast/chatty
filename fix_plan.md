# Fix Plan

## Tasks

### 1. project-setup
- **id**: project-setup
- **rationale**: Initialize Swift package structure with proper dependencies and build configuration
- **acceptance**: 
  - Package.swift exists with macOS 14.0 platform
  - Build succeeds with `swift build`
  - Basic app target launches
- **files**: Package.swift, .gitignore, Sources/ChattyApp/ChattyApp.swift
- **est_effort**: XS
- **dependencies**: []

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