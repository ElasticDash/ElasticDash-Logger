# Data Model Reference

## Overview

ElasticDash Logger stores execution data from LLM applications using a hierarchical structure based on Langfuse's data model. Understanding this structure is essential for querying traces and building evaluations.

> **Note**: This document describes the logical data model. For implementation details about how this data is stored in PostgreSQL and ClickHouse within this repository, see the [Architecture Overview](./architecture.md#database-architecture).

**Three core concepts**:
1. **Observations** - Individual steps (LLM calls, tool executions, etc.)
2. **Traces** - Complete request/response flows containing observations
3. **Sessions** - Groups of related traces (e.g., multi-turn conversations)

```
Session (optional)
  │
  ├─► Trace 1
  │     ├─► Observation 1
  │     ├─► Observation 2
  │     │     └─► Observation 2.1 (nested)
  │     └─► Observation 3
  │
  ├─► Trace 2
  │     ├─► Observation 4
  │     └─► Observation 5
  │
  └─► Trace 3
        └─► Observation 6
```

---

## Traces

### Definition

A **trace** represents a single request or operation in your LLM application. For example:
- A user asking a question to a chatbot
- A single API call to your LLM service
- One execution of an agent workflow

### Trace Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | `string` | Unique identifier for the trace |
| `name` | `string` | Human-readable name (e.g., "chat-completion", "summarize-document") |
| `userId` | `string` | End-user who triggered this trace (optional) |
| `sessionId` | `string` | ID of the session this trace belongs to (optional) |
| `input` | `object` | Input data sent to the application (e.g., user message) |
| `output` | `object` | Final output produced by the application |
| `metadata` | `object` | Custom key-value pairs for additional context |
| `tags` | `string[]` | Labels for categorization (e.g., `["production", "gpt-4"]`) |
| `timestamp` | `datetime` | When the trace started |
| `release` | `string` | Application version that generated this trace (optional) |
| `version` | `string` | Trace schema version (optional) |

### Example Trace

```json
{
  "id": "trace-abc123",
  "name": "chat-completion",
  "userId": "user-456",
  "sessionId": "session-789",
  "input": {
    "messages": [
      {"role": "user", "content": "What is the capital of France?"}
    ]
  },
  "output": {
    "content": "The capital of France is Paris."
  },
  "metadata": {
    "model": "gpt-4",
    "environment": "production"
  },
  "tags": ["chat", "geography"],
  "timestamp": "2026-02-15T10:30:00Z"
}
```

---

## Sessions

### Definition

A **session** groups multiple related traces together. Sessions are useful for:
- **Multi-turn conversations** - A chat thread with multiple back-and-forth exchanges
- **Workflows** - A sequence of operations that belong together
- **User journeys** - All interactions for a single user task

### Session Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | `string` | Unique identifier for the session |
| `createdAt` | `datetime` | When the session was created |
| `traces` | `Trace[]` | Array of traces belonging to this session |

### When to Use Sessions

Use sessions when you need to:
- Track conversation history across multiple requests
- Analyze user behavior over time
- Evaluate multi-step workflows as a whole
- Group traces for replay or testing

### Example: Chat Session

```
Session ID: session-789

Trace 1 (10:30:00):
  User: "What is the capital of France?"
  Bot: "The capital of France is Paris."

Trace 2 (10:30:15):
  User: "What is its population?"
  Bot: "Paris has a population of approximately 2.2 million."

Trace 3 (10:30:45):
  User: "Tell me about the Eiffel Tower."
  Bot: "The Eiffel Tower is an iconic iron lattice tower..."
```

All three traces share `sessionId: "session-789"`, making it easy to fetch the entire conversation.

---

## Observations

### Definition

An **observation** is a single step within a trace. Observations can be nested to represent hierarchical execution.

### Observation Types

ElasticDash Logger supports several observation types from Langfuse:

| Type | Description | Use Case |
|------|-------------|----------|
| `SPAN` | Generic execution block | Wrapping multiple operations, custom logic blocks |
| `GENERATION` | LLM model call | Calls to OpenAI, Anthropic, etc. |
| `EVENT` | Discrete event with no duration | Logging, checkpoints, status updates |

### Observation Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | `string` | Unique identifier for the observation |
| `traceId` | `string` | Parent trace ID |
| `parentObservationId` | `string` | Parent observation ID for nesting (optional) |
| `type` | `string` | One of: `SPAN`, `GENERATION`, `EVENT` |
| `name` | `string` | Human-readable name (e.g., "gpt-4-call", "retrieval") |
| `startTime` | `datetime` | When the observation started |
| `endTime` | `datetime` | When the observation ended (null for events) |
| `input` | `object` | Input data for this step |
| `output` | `object` | Output data from this step |
| `metadata` | `object` | Custom key-value pairs |
| `level` | `string` | Severity level: `DEBUG`, `DEFAULT`, `WARNING`, `ERROR` |
| `statusMessage` | `string` | Status or error message (optional) |

#### Additional Attributes for GENERATION Type

For observations of type `GENERATION`, additional LLM-specific fields are available:

| Attribute | Type | Description |
|-----------|------|-------------|
| `model` | `string` | Model identifier (e.g., "gpt-4", "claude-3-opus") |
| `modelParameters` | `object` | Parameters like temperature, max_tokens, top_p |
| `usage` | `object` | Token usage: `{ promptTokens, completionTokens, totalTokens }` |
| `promptTokens` | `number` | Number of tokens in the prompt |
| `completionTokens` | `number` | Number of tokens in the completion |
| `totalTokens` | `number` | Total tokens used |
| `calculatedTotalCost` | `number` | Estimated cost in USD (if available) |

### Nested Observations

Observations can be nested to represent hierarchical execution:

```
Trace: "handle-user-query"
  │
  ├─► Observation (SPAN): "process-request"
  │     ├─► Observation (GENERATION): "embedding-call"
  │     ├─► Observation (SPAN): "vector-search"
  │     │     └─► Observation (EVENT): "cache-hit"
  │     └─► Observation (GENERATION): "gpt-4-completion"
  │
  └─► Observation (EVENT): "response-logged"
```

In this example:
- The root trace contains a main SPAN observation
- The SPAN contains nested observations for embedding, search, and completion
- The search SPAN contains an EVENT observation
- Nesting is represented via `parentObservationId`

### Example Observation (GENERATION)

```json
{
  "id": "obs-xyz789",
  "traceId": "trace-abc123",
  "parentObservationId": null,
  "type": "GENERATION",
  "name": "gpt-4-completion",
  "startTime": "2026-02-15T10:30:00.100Z",
  "endTime": "2026-02-15T10:30:02.350Z",
  "input": {
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ]
  },
  "output": {
    "role": "assistant",
    "content": "The capital of France is Paris."
  },
  "model": "gpt-4",
  "modelParameters": {
    "temperature": 0.7,
    "max_tokens": 150
  },
  "usage": {
    "promptTokens": 25,
    "completionTokens": 8,
    "totalTokens": 33
  },
  "calculatedTotalCost": 0.00099,
  "metadata": {
    "environment": "production"
  }
}
```

---

## Relationships

### Hierarchy

```
Session (1)
  ├─► has many Traces (n)

Trace (1)
  ├─► has many Observations (n)
  ├─► has input, output, metadata
  └─► belongs to Session (0..1)

Observation (1)
  ├─► belongs to Trace (1)
  ├─► has parent Observation (0..1)
  └─► has many child Observations (n)
```

### Querying by Relationship

**Fetch all traces in a session**:
```python
from elasticdash import get_client

elasticdash = get_client()
traces = elasticdash.api.trace.list(session_id="session-789")
```

**Fetch all observations in a trace**:
```python
observations = elasticdash.api.observations_v_2.get_many(trace_id="trace-abc123")
```

**Filter traces by user**:
```python
traces = elasticdash.api.trace.list(user_id="user-456")
```

---

## Additional Attributes

### Tags

**Purpose**: Categorize and filter traces

**Examples**:
```python
tags = ["production", "gpt-4", "chat", "high-priority"]
```

**Use cases**:
- Filter by environment (`"production"`, `"staging"`)
- Filter by model (`"gpt-4"`, `"claude-3"`)
- Filter by feature (`"summarization"`, `"translation"`)

### Metadata

**Purpose**: Store arbitrary key-value pairs for custom context

**Examples**:
```json
{
  "customer_tier": "premium",
  "region": "us-east-1",
  "experiment_id": "exp-42",
  "ab_test_variant": "B"
}
```

**Use cases**:
- A/B test tracking
- Customer segmentation
- Feature flags
- Custom business logic

### User Tracking

**Purpose**: Link traces to end-users

**Usage**:
```python
from elasticdash import get_client

elasticdash = get_client()

with elasticdash.start_as_current_observation(
    as_type="span",
    name="chat-completion",
    user_id="user-456"  # End-user identifier
) as span:
    span.update(input={"message": "Hello"})
```

**Use cases**:
- User-specific analytics
- Per-user evaluation
- Support and debugging

---

## Timestamps and Latency

All traces and observations include timing information:

| Field | Description |
|-------|-------------|
| `timestamp` / `startTime` | When execution began |
| `endTime` | When execution completed (null for events) |
| Calculated latency | `endTime - startTime` |

**Example**: Analyzing latency
```python
from elasticdash import get_client

elasticdash = get_client()

# Fetch observations and calculate latency
observations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    type="GENERATION"
)

for obs in observations:
    if obs.endTime and obs.startTime:
        latency = obs.endTime - obs.startTime
        print(f"{obs.name}: {latency}ms")
```

---

## Best Practices

### Naming Conventions

- **Traces**: Use descriptive names that indicate the operation (e.g., `"chat-completion"`, `"document-summarization"`)
- **Observations**: Use step-specific names (e.g., `"gpt-4-call"`, `"vector-search"`, `"parse-response"`)

### Metadata and Tags

- **Tags**: Use for high-cardinality categorization (environment, model, feature)
- **Metadata**: Use for low-cardinality context (experiment IDs, customer tier, region)

### Sessions

- Always use sessions for multi-turn conversations
- Use consistent `sessionId` across all traces in a conversation
- Consider creating new sessions for new user intents or topics

### User IDs

- Always include `userId` when traces are linked to end-users
- Use consistent user identifiers across your application

---

---

## Database Implementation in ElasticDash Logger

This repository implements the data model using a **dual-database architecture**:

### PostgreSQL (Metadata)
Stores project configuration, users, API keys, and organizational data.

**Key Tables** (see `/packages/shared/prisma/schema.prisma`):
- `Project` - Project configuration and settings
- `ApiKey` - Authentication credentials
- `User` - User accounts
- `Organization` - Organization details

### ClickHouse (Trace Data)
Stores high-volume trace data for fast querying and analytics.

**Key Tables** (see `/packages/shared/clickhouse/`):
- `traces` - Trace metadata and hierarchy
- `observations` - Individual steps (spans, generations, events)
- `scores` - Evaluation scores and ratings
- `trace_sessions` - Session groupings

**Why Two Databases?**
- PostgreSQL: ACID compliance for critical configuration data
- ClickHouse: Columnar storage optimized for time-series trace data at scale

See [Architecture Overview](./architecture.md#database-architecture) for full details.

---

## See Also

- [Architecture Overview](./architecture.md) - How the Logger is architected
- [Fetching Data](./fetching-data.md) - Query traces, sessions, and observations from the Logger
- [SDK Overview](./sdk-overview.md) - Instrument your application to send traces
