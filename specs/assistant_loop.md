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