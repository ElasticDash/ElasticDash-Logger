# Fetching Data from ElasticDash Logger

This guide explains how to retrieve traces, sessions, and observations from the ElasticDash Logger using the REST API and SDKs.

> **Note**: This guide covers querying the Logger via its public API. This is intended for:
> - External applications integrating with ElasticDash Logger
> - Custom data analysis tools
> - Third-party services that need trace data
>
> See [Architecture Overview](./architecture.md) for information about the Logger's architecture.

---

## Overview

ElasticDash Logger provides public APIs for querying trace data:

- **RESTful endpoints** for fetching traces, sessions, observations, and scores
- **Python SDK** with type-safe wrappers (`elasticdash` package)
- **JavaScript/TypeScript SDK** with type-safe wrappers (`@elasticdash/client` package)

All data is typically available for querying within **15-30 seconds** of ingestion.

### Prerequisites

Before querying data, you need a running ElasticDash Logger instance. The easiest way is Docker Compose:

```bash
docker-compose up -d
# Access at http://localhost:3000
```

See [SDK Overview](./sdk-overview.md#prerequisites-running-elasticdash-logger) for details.

---

## Authentication

ElasticDash Logger uses **HTTP Basic Authentication** for API access.

### API Keys

API keys are project-scoped and can be obtained from the Logger's project settings.

Each project has:
- **Public Key** (username): `pk-lf-...`
- **Secret Key** (password): `sk-lf-...`

### Authentication Example

```bash
curl -u pk-lf-xxx:sk-lf-xxx https://logger.example.com/api/public/traces
```

---

## REST API

### Base URL

The base URL depends on your deployment:

```
https://your-logger-host.com/api/public
```

For example:
```
https://logger.elasticdash.example.com/api/public
```

### API Reference

API documentation is available at:
- OpenAPI Spec: `https://your-logger-host.com/generated/api/openapi.yml`
- Logger is compatible with Langfuse API specification

### Common Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/traces` | GET | List traces with filters |
| `/traces/{traceId}` | GET | Get single trace by ID |
| `/sessions` | GET | List sessions |
| `/sessions/{sessionId}` | GET | Get single session by ID |
| `/observations` | GET | List observations (v1) |
| `/observations-v2` | GET | List observations with better performance (v2) |
| `/scores` | GET | List scores |

---

## Python SDK

The Python SDK provides a convenient wrapper around the REST API.

### Installation

```bash
pip install elasticdash
```

### Initialization

```python
from elasticdash import get_client

# Initialize with environment variables
elasticdash = get_client()

# Or explicitly pass credentials
elasticdash = get_client(
    public_key="pk-lf-xxx",
    secret_key="sk-lf-xxx",
    host="https://logger.elasticdash.example.com"
)
```

### Environment Variables

```bash
ELASTICDASH_PUBLIC_KEY="pk-lf-xxx"
ELASTICDASH_SECRET_KEY="sk-lf-xxx"
ELASTICDASH_BASE_URL="https://logger.elasticdash.example.com"
# Or for local Docker: http://localhost:3000
```

### Fetching Traces

#### List All Traces

```python
traces = elasticdash.api.trace.list(limit=100)

for trace in traces.data:
    print(f"Trace ID: {trace.id}")
    print(f"Name: {trace.name}")
    print(f"User: {trace.user_id}")
    print(f"Session: {trace.session_id}")
    print("---")
```

#### Get Single Trace

```python
trace = elasticdash.api.trace.get("trace-abc123")

print(f"Trace: {trace.name}")
print(f"Input: {trace.input}")
print(f"Output: {trace.output}")
print(f"Metadata: {trace.metadata}")
```

#### Filter Traces

```python
# Filter by user
traces = elasticdash.api.trace.list(user_id="user-456", limit=50)

# Filter by session
traces = elasticdash.api.trace.list(session_id="session-789", limit=50)

# Filter by tags
traces = elasticdash.api.trace.list(tags=["production", "gpt-4"], limit=50)

# Filter by name
traces = elasticdash.api.trace.list(name="chat-completion", limit=50)

# Time range filter (timestamps as ISO 8601 strings)
traces = elasticdash.api.trace.list(
    from_timestamp="2026-02-01T00:00:00Z",
    to_timestamp="2026-02-15T23:59:59Z",
    limit=100
)
```

#### Pagination

```python
# First page
response = elasticdash.api.trace.list(limit=100)
traces = response.data

# Next page (using cursor from previous response)
if response.meta.next:
    next_response = elasticdash.api.trace.list(limit=100, cursor=response.meta.next)
    traces.extend(next_response.data)
```

### Fetching Sessions

#### List All Sessions

```python
sessions = elasticdash.api.sessions.list(limit=50)

for session in sessions.data:
    print(f"Session ID: {session.id}")
    print(f"Created At: {session.created_at}")
    print("---")
```

#### Get Single Session

```python
session = elasticdash.api.sessions.get("session-789")

print(f"Session ID: {session.id}")
print(f"Number of traces: {len(session.traces)}")
```

### Fetching Observations

#### Using V2 API (Recommended)

The v2 API offers better performance with cursor-based pagination and selective field retrieval.

```python
observations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    type="GENERATION",
    limit=100,
    fields="core,basic,usage"  # Selective fields for better performance
)

for obs in observations.data:
    print(f"Observation: {obs.name}")
    print(f"Type: {obs.type}")
    print(f"Model: {obs.model}")
    print(f"Tokens: {obs.usage}")
    print("---")
```

**Available fields for selective retrieval**:
- `core`: Essential fields (id, type, name, timestamps)
- `basic`: Basic details (input, output, metadata)
- `usage`: Token usage and costs
- `scores`: Associated scores

#### Using V1 API

```python
# Get observations for a trace
observations = elasticdash.api.observations.get_many(
    trace_id="trace-abc123",
    type="GENERATION",
    limit=100
)

# Get single observation
observation = elasticdash.api.observations.get("obs-xyz789")
```

#### Filter by Type

```python
# Get only GENERATION observations (LLM calls)
generations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    type="GENERATION"
)

# Get only SPAN observations
spans = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    type="SPAN"
)
```

### Async Support

All endpoints have async equivalents under `async_api`:

```python
import asyncio

async def fetch_traces():
    trace = await elasticdash.async_api.trace.get("trace-abc123")
    print(trace.name)

    traces = await elasticdash.async_api.trace.list(limit=100)
    print(f"Found {len(traces.data)} traces")

asyncio.run(fetch_traces())
```

---

## JavaScript/TypeScript SDK

### Installation

```bash
npm install @elasticdash/client
```

### Initialization

```typescript
import { ElasticDashClient } from '@elasticdash/client';

// Initialize with environment variables
const elasticdash = new ElasticDashClient();

// Or explicitly pass credentials
const elasticdash = new ElasticDashClient({
  publicKey: "pk-lf-xxx",
  secretKey: "sk-lf-xxx",
  baseUrl: "https://logger.elasticdash.example.com"
});
```

### Environment Variables

```bash
ELASTICDASH_PUBLIC_KEY="pk-lf-xxx"
ELASTICDASH_SECRET_KEY="sk-lf-xxx"
ELASTICDASH_BASE_URL="https://logger.elasticdash.example.com"
# Or for local Docker: http://localhost:3000
```

### Fetching Traces

#### List All Traces

```typescript
const traces = await elasticdash.api.trace.list({ limit: 100 });

for (const trace of traces.data) {
  console.log(`Trace ID: ${trace.id}`);
  console.log(`Name: ${trace.name}`);
  console.log(`User: ${trace.userId}`);
}
```

#### Get Single Trace

```typescript
const trace = await elasticdash.api.trace.get("trace-abc123");

console.log(`Trace: ${trace.name}`);
console.log(`Input:`, trace.input);
console.log(`Output:`, trace.output);
```

#### Filter Traces

```typescript
// Filter by user
const userTraces = await elasticdash.api.trace.list({
  userId: "user-456",
  limit: 50
});

// Filter by session
const sessionTraces = await elasticdash.api.trace.list({
  sessionId: "session-789",
  limit: 50
});

// Filter by tags
const taggedTraces = await elasticdash.api.trace.list({
  tags: ["production", "gpt-4"],
  limit: 50
});

// Time range filter
const recentTraces = await elasticdash.api.trace.list({
  fromTimestamp: "2026-02-01T00:00:00Z",
  toTimestamp: "2026-02-15T23:59:59Z",
  limit: 100
});
```

### Fetching Sessions

```typescript
// List sessions
const sessions = await elasticdash.api.sessions.list({ limit: 50 });

// Get single session
const session = await elasticdash.api.sessions.get("session-789");
console.log(`Session has ${session.traces.length} traces`);
```

### Fetching Observations

#### Using V2 API (Recommended)

```typescript
const observations = await elasticdash.api.observationsV2.getMany({
  traceId: "trace-abc123",
  type: "GENERATION",
  limit: 100,
  fields: "core,basic,usage"
});

for (const obs of observations.data) {
  console.log(`${obs.name}: ${obs.model}`);
  console.log(`Tokens: ${obs.usage?.totalTokens}`);
}
```

#### Using V1 API

```typescript
// Get observations for a trace
const observations = await elasticdash.api.observations.getMany({
  traceId: "trace-abc123",
  type: "GENERATION"
});

// Get single observation
const observation = await elasticdash.api.observations.get("obs-xyz789");
```

---

## Common Use Cases

### 1. Fetch All Traces for a User

**Python**:
```python
user_traces = elasticdash.api.trace.list(user_id="user-456", limit=1000)

for trace in user_traces.data:
    print(f"{trace.name}: {trace.output}")
```

**TypeScript**:
```typescript
const userTraces = await elasticdash.api.trace.list({
  userId: "user-456",
  limit: 1000
});
```

### 2. Fetch Entire Conversation (Session)

**Python**:
```python
# Get session with all traces
session = elasticdash.api.sessions.get("session-789")

# Get detailed traces
for trace_summary in session.traces:
    trace = elasticdash.api.trace.get(trace_summary.id)
    print(f"User: {trace.input}")
    print(f"Bot: {trace.output}")
    print("---")
```

**TypeScript**:
```typescript
const session = await elasticdash.api.sessions.get("session-789");

for (const traceSummary of session.traces) {
  const trace = await elasticdash.api.trace.get(traceSummary.id);
  console.log(`User: ${trace.input}`);
  console.log(`Bot: ${trace.output}`);
}
```

### 3. Analyze LLM Usage and Costs

**Python**:
```python
# Get all GENERATION observations for a trace
observations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    type="GENERATION",
    fields="core,basic,usage"
)

total_tokens = 0
total_cost = 0.0

for obs in observations.data:
    if obs.usage:
        total_tokens += obs.usage.get('totalTokens', 0)
    if obs.calculated_total_cost:
        total_cost += obs.calculated_total_cost

print(f"Total tokens: {total_tokens}")
print(f"Total cost: ${total_cost:.4f}")
```

### 4. Filter by Time Range and Tags

**Python**:
```python
production_traces = elasticdash.api.trace.list(
    tags=["production"],
    from_timestamp="2026-02-15T00:00:00Z",
    to_timestamp="2026-02-15T23:59:59Z",
    limit=500
)

print(f"Found {len(production_traces.data)} production traces today")
```

### 5. Fetch Traces with Specific Metadata

**Python**:
```python
# Note: Direct metadata filtering might not be supported
# Fetch traces and filter in application code
all_traces = elasticdash.api.trace.list(limit=1000)

# Filter by metadata in code
filtered = [
    trace for trace in all_traces.data
    if trace.metadata.get("experiment_id") == "exp-42"
]

print(f"Found {len(filtered)} traces for experiment exp-42")
```

### 6. Export Traces for Analysis

**Python**:
```python
import json

# Fetch all traces for a session
traces = elasticdash.api.trace.list(session_id="session-789", limit=100)

# Export to JSON
with open("session_traces.json", "w") as f:
    json.dump([t.dict() for t in traces.data], f, indent=2, default=str)

print("Exported to session_traces.json")
```

---

## Pagination Best Practices

When fetching large datasets, use pagination to avoid timeouts and memory issues.

### Python Example

```python
def fetch_all_traces(user_id):
    all_traces = []
    cursor = None

    while True:
        response = elasticdash.api.trace.list(
            user_id=user_id,
            limit=100,
            cursor=cursor
        )

        all_traces.extend(response.data)

        # Check if there are more pages
        if not response.meta.next:
            break

        cursor = response.meta.next

    return all_traces

traces = fetch_all_traces("user-456")
print(f"Fetched {len(traces)} traces")
```

### TypeScript Example

```typescript
async function fetchAllTraces(userId: string) {
  const allTraces = [];
  let cursor = undefined;

  while (true) {
    const response = await elasticdash.api.trace.list({
      userId,
      limit: 100,
      cursor
    });

    allTraces.push(...response.data);

    if (!response.meta.next) {
      break;
    }

    cursor = response.meta.next;
  }

  return allTraces;
}

const traces = await fetchAllTraces("user-456");
console.log(`Fetched ${traces.length} traces`);
```

---

## Performance Considerations

### Use V2 APIs Where Available

The v2 APIs (e.g., `observations_v_2`) offer:
- Cursor-based pagination (faster than offset-based)
- Selective field retrieval (reduced payload size)
- Better query performance

```python
# Faster: only fetch fields you need
observations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-abc123",
    fields="core,usage"  # Only core fields and usage
)

# Slower: fetches all fields
observations = elasticdash.api.observations.get_many(trace_id="trace-abc123")
```

### Limit Result Sizes

Always specify a `limit` to avoid fetching too much data at once:

```python
# Good
traces = elasticdash.api.trace.list(limit=100)

# Bad: might fetch thousands of traces
traces = elasticdash.api.trace.list()
```

### Use Specific Filters

Filter at the API level rather than fetching all data and filtering in code:

```python
# Good: filter in API
traces = elasticdash.api.trace.list(user_id="user-456", tags=["production"])

# Bad: fetch everything and filter in code
all_traces = elasticdash.api.trace.list(limit=10000)
filtered = [t for t in all_traces.data if t.user_id == "user-456"]
```

---

## Error Handling

### Python

```python
from elasticdash import LangfuseException

try:
    trace = elasticdash.api.trace.get("invalid-trace-id")
except LangfuseException as e:
    print(f"Error fetching trace: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

### TypeScript

```typescript
try {
  const trace = await elasticdash.api.trace.get("invalid-trace-id");
} catch (error) {
  console.error("Error fetching trace:", error);
}
```

---

## Rate Limits

ElasticDash Logger may have rate limits in place to prevent abuse. If you encounter rate limit errors:

1. Reduce request frequency
2. Use pagination with smaller page sizes
3. Cache results where possible
4. Implement exponential backoff retry logic

---

## See Also

- [Data Model Reference](./data-model.md) - Understanding traces, sessions, and observations
- [Architecture Overview](./architecture.md) - How ElasticDash components interact
- Langfuse API Reference: https://api.reference.elasticdash.com
