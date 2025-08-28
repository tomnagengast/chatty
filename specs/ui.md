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