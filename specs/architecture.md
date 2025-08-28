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