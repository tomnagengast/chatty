# Chatty - Native macOS/iOS MCP Client

A native Swift implementation of a Model Context Protocol (MCP) client with an integrated assistant engine, inspired by the [Ralph engineering methodology](https://ghuntley.com/ralph/).

## Overview

Chatty is a macOS/iOS application that combines:
- **MCP Client**: Full-featured client supporting stdio and HTTP/SSE transports
- **Assistant Engine**: Ralph-style deterministic loop processing with context management
- **Native UI**: SwiftUI interface optimized for Apple platforms

## Architecture

The project follows Ralph principles:
- **Deterministic Stack Allocation**: Consistent context injection each iteration
- **Single Task Focus**: One atomic change per loop iteration  
- **Backpressure Engineering**: Real validation through build/test/lint
- **Signs Over Vibes**: Explicit rules prevent common failure modes

## Ralph Loop Setup

This project uses an automated Ralph loop for development. Each iteration:
1. Reads all specs and the fix plan
2. Selects the next unblocked task
3. Makes minimal, compilable changes
4. Validates with real Swift toolchain
5. Commits on green builds only

## Prerequisites

- **macOS 14.0+** with Xcode 15+
- **Swift 6.2+** (verify with `swift --version`)
- **Claude CLI** ([install instructions](https://docs.anthropic.com/en/docs/claude-code))
- **Git** (for version control)

### Optional Tools

```bash
# For code formatting
brew install swift-format

# For linting
brew install swiftlint
```

## Running Ralph

### First Time Setup

```bash
# Clone and enter the repository
git clone <repository-url> chatty
cd chatty

# Initialize the environment
./scripts/bootstrap_env.sh
```

### Run an Iteration

Execute a single Ralph iteration:

```bash
./scripts/run_iteration.sh
```

This will:
1. Select the next task from `fix_plan.md`
2. Generate and apply code changes
3. Run validation (format → build → test → lint)
4. Output `true` if successful, `false` if validation fails

### Commit on Success

After a successful iteration:

```bash
# Review changes
git status
git diff

# Commit if satisfied
git add .
git commit -m "Complete: <task-id>"
```

### Continuous Loop

For continuous development:

```bash
# Run iterations until all tasks complete
while ./scripts/run_iteration.sh; do
  git add .
  git commit -m "Ralph iteration $(date +%s)"
  echo "✅ Iteration complete"
  sleep 2
done
```

## Project Structure

```
chatty/
├── CLAUDE.md           # Project-specific instructions
├── fix_plan.md         # Task queue (Ralph picks from here)
├── specs/              # Architectural specifications
│   ├── architecture.md # Overall system design
│   ├── assistant_loop.md # Ralph engine specs
│   ├── mcp_client.md   # MCP protocol implementation
│   └── ui.md           # User interface specifications
├── scripts/
│   ├── bootstrap_env.sh # Initial setup
│   └── run_iteration.sh # Ralph loop executor
├── Sources/            # Swift source code
│   ├── ChattyApp/      # SwiftUI application
│   ├── MCPClient/      # MCP client implementation
│   └── Assistant/      # Assistant engine
└── Tests/              # Unit and integration tests
```

## Monitoring Progress

### Check Current Status

```bash
# View last iteration output
cat .claude/.last-iteration.json | jq .

# View validation results  
cat .claude/.last-validation.json | jq .

# See remaining tasks
grep "^### " fix_plan.md
```

### Debug Failed Iterations

If an iteration fails:

```bash
# Check validation details
cat .claude/.last-validation.json | jq '.build.details, .tests.failures'

# Review generated diffs
cat .claude/.last-iteration.json | jq -r '.diffs[].unified_diff'

# Manually fix and retry
vim <problem-file>
./scripts/run_iteration.sh
```

## Development Workflow

1. **Add Tasks**: Edit `fix_plan.md` to add new tasks at the end
2. **Update Specs**: Modify files in `specs/` for architectural changes
3. **Adjust Signs**: Edit `CLAUDE.md` to add project-specific rules
4. **Run Ralph**: Execute `./scripts/run_iteration.sh`
5. **Validate**: Ensure builds and tests pass
6. **Commit**: Save progress with meaningful commit messages

## Extending Ralph

### Custom Validation

Edit `scripts/run_iteration.sh` lines 80-157 to add custom validation steps:

```bash
# Add security scanning
if command -v gosec >/dev/null; then
  gosec ./... 2>&1
fi
```

### New Spec Files

Drop any `.md` file in `specs/` - it's automatically included in the next iteration.

### Task Dependencies

In `fix_plan.md`, use the dependencies field to control task ordering:

```yaml
- id: new-feature
  dependencies: [mcp-client-core, ui-setup]
```

## Troubleshooting

### Claude CLI Issues

```bash
# Verify Claude CLI installation
claude --version

# Check API key
echo $ANTHROPIC_API_KEY
```

### Swift Build Failures

```bash
# Clean build artifacts
swift package clean
rm -rf .build/

# Reset package dependencies  
swift package reset
```

### Git Conflicts

```bash
# Abort failed patch
git apply --abort

# Reset to last commit
git reset --hard HEAD
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run Ralph iterations for changes
4. Ensure all tests pass
5. Submit a pull request

## License

[Specify your license here]

## Acknowledgments

- [Ralph methodology](https://ghuntley.com/ralph/) by Geoffrey Huntley
- [Model Context Protocol](https://modelcontextprotocol.io/) specification
- Claude Code for AI-assisted development