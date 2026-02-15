# Instrumenting Applications with ElasticDash Logger

> **Note**: This guide covers client SDKs for **sending traces to** ElasticDash Logger. The SDKs are maintained in separate repositories and are compatible with the Langfuse protocol.
>
> **This repository (ElasticDash-Logger)** contains the server-side Logger application that **receives** traces from these SDKs.

ElasticDash Logger works with ElasticDash SDKs, which provide fully-typed instrumentation for your LLM applications.

- **Python** - `elasticdash` package on PyPI
- **JavaScript/TypeScript** - `@elasticdash/tracing` and `@elasticdash/otel` packages on npm

These SDKs are the recommended way to create traces and observations in your LLM applications.

---

## Prerequisites: Running ElasticDash Logger

Before instrumenting your application, you need a running ElasticDash Logger instance.

### Easiest Way: Docker Compose ⭐ **Recommended**

The fastest way to get started is using Docker Compose:

```bash
# Clone the repository
git clone https://github.com/your-org/ElasticDash-Logger.git
cd ElasticDash-Logger

# Start all services with Docker Compose
docker-compose up -d

# Access the Logger
# Web UI: http://localhost:3000
# API: http://localhost:3000/api/public
```

This single command starts:
- ✅ ElasticDash Logger (web + worker)
- ✅ PostgreSQL database
- ✅ ClickHouse database
- ✅ Redis queue
- ✅ MinIO storage

**Create a project and get API keys:**
1. Open http://localhost:3000
2. Sign up / Sign in
3. Create a new project
4. Copy your API keys (Public Key & Secret Key)

### Alternative: Local Development

For development on the Logger itself:

```bash
pnpm install
pnpm run infra:dev:up  # Start infrastructure only
pnpm run dev           # Run web + worker in dev mode
```

See the [Architecture Guide](./architecture.md) for details.

---

## What Do the SDKs Do?

The ElasticDash SDKs enable you to:

1. **Instrument your application** - Capture traces of LLM calls, tool executions, and custom logic
2. **Record observations** - Track individual steps like model generations, retrievals, and events
3. **Add metadata** - Attach user IDs, session IDs, tags, and custom metadata to traces
4. **Async tracing** - Send traces in the background without adding latency to your application
5. **Automatic nesting** - Create hierarchical traces that show parent-child relationships

**Key Benefits:**

- Built on [OpenTelemetry](https://opentelemetry.io/) standard
- Fully async requests (no latency impact)
- Accurate latency tracking with synchronous timestamps
- Type-safe APIs with IntelliSense support
- Automatic error handling (SDK errors won't break your app)
- Compatible with popular frameworks (OpenAI, LangChain, etc.)

---

## Quick Start

### Python SDK

**1. Install package:**

```bash
pip install elasticdash
```

**2. Add credentials:**

Get your API keys from the Logger web UI (http://localhost:3000) after creating a project.

```bash
# .env file
ELASTICDASH_SECRET_KEY="sk-lf-..."
ELASTICDASH_PUBLIC_KEY="pk-lf-..."
ELASTICDASH_BASE_URL="http://localhost:3000"  # Your Logger URL
```

**3. Instrument your application:**

```python
from elasticdash import get_client

# Initialize client
elasticdash = get_client()

# Create a trace with a generation (LLM call)
with elasticdash.start_as_current_observation(
    as_type="generation",
    name="gpt-4-completion",
    model="gpt-4"
) as generation:
    generation.update(
        input={"prompt": "What is the capital of France?"},
        output={"response": "The capital of France is Paris."},
        usage={
            "prompt_tokens": 10,
            "completion_tokens": 8,
            "total_tokens": 18
        }
    )

# Flush events (required for short-lived apps)
elasticdash.flush()
```

**4. See your trace in ElasticDash Logger**

Navigate to http://localhost:3000 to view the captured trace in the Logger UI.

---

### JavaScript/TypeScript SDK

**1. Install package:**

```bash
npm install @elasticdash/tracing @elasticdash/otel
```

**2. Set environment variables:**

Get your API keys from the Logger web UI (http://localhost:3000) after creating a project.

```bash
# .env file
ELASTICDASH_SECRET_KEY="sk-lf-..."
ELASTICDASH_PUBLIC_KEY="pk-lf-..."
ELASTICDASH_BASE_URL="http://localhost:3000"  # Your Logger URL
```

**3. Instrument your application:**

```typescript
import { startActiveObservation } from "@elasticdash/tracing";
import { sdk } from "./instrumentation";  // OpenTelemetry SDK setup

async function main() {
  await startActiveObservation("gpt-4-completion", async (generation) => {
    generation.update({
      model: "gpt-4",
      input: { query: "What is the capital of France?" },
      output: { answer: "Paris" },
      usage: {
        promptTokens: 10,
        completionTokens: 8,
        totalTokens: 18
      }
    });
  });
}

main().finally(() => sdk.shutdown());
```

**4. Run and see your trace:**

```bash
node index.js
```

Navigate to http://localhost:3000 to view your traces.

---

## Installation

### Python SDK

Install the ElasticDash Python SDK from PyPI:

```bash
pip install elasticdash
```

**Requirements:**
- Python 3.8 or higher
- Compatible with async/await patterns

### JavaScript/TypeScript SDK

Install the ElasticDash JS/TS SDK from npm:

```bash
npm install @elasticdash/tracing @elasticdash/otel
```

**Additional Packages:**

ElasticDash provides integrations for popular frameworks:

```bash
# For OpenAI integration
npm install @elasticdash/openai

# For LangChain integration
npm install @elasticdash/langchain
```

---

## Configuration

### Environment Variables

Both SDKs support configuration via environment variables:

```bash
# Required
ELASTICDASH_PUBLIC_KEY="pk-lf-..."
ELASTICDASH_SECRET_KEY="sk-lf-..."

# Required - point to your Logger instance
ELASTICDASH_BASE_URL="http://localhost:3000"  # For local Docker setup
# or
ELASTICDASH_BASE_URL="https://logger.your-domain.com"  # For production
```

**Getting API Keys:**
1. Start ElasticDash Logger (easiest: `docker-compose up -d`)
2. Open http://localhost:3000
3. Create a project
4. Copy your Public Key and Secret Key from project settings

### Python: Client Initialization

**Using environment variables (recommended):**

```python
from elasticdash import get_client

# Automatically uses environment variables
elasticdash = get_client()

# Verify connection
if elasticdash.auth_check():
    print("Connected to ElasticDash Logger!")
else:
    print("Authentication failed - check your API keys")
```

**Using constructor:**

```python
from elasticdash import ElasticDashClient

elasticdash = ElasticDashClient(
    public_key="pk-lf-...",
    secret_key="sk-lf-...",
    host="http://localhost:3000"  # Your Logger URL
)
```

### JavaScript/TypeScript: Client Initialization

**Using environment variables:**

Set up OpenTelemetry in your `instrumentation.ts` file:

```typescript
// instrumentation.ts
import { setupElasticDash } from "@elasticdash/otel";

export const sdk = setupElasticDash({
  serviceName: "my-app"
});
```

**Using constructor:**

```typescript
import { setupElasticDash } from "@elasticdash/otel";

export const sdk = setupElasticDash({
  serviceName: "my-app",
  publicKey: "pk-lf-...",
  secretKey: "sk-lf-...",
  baseUrl: "http://localhost:3000"  // Your Logger URL
});
```

---

## Basic Usage

### Creating Traces

**Python:**

```python
from elasticdash import get_client

elasticdash = get_client()

# Context manager (recommended)
with elasticdash.start_as_current_observation(
    as_type="span",
    name="my-operation"
) as span:
    span.update(
        input="Input data",
        output="Output data",
        metadata={"user": "alice"}
    )
```

**TypeScript:**

```typescript
import { startActiveObservation } from "@elasticdash/tracing";

await startActiveObservation("my-operation", async (span) => {
  span.update({
    input: "Input data",
    output: "Output data",
    metadata: { user: "alice" }
  });
});
```

### Recording LLM Generations

**Python:**

```python
with elasticdash.start_as_current_observation(
    as_type="generation",
    name="gpt-4-call",
    model="gpt-4"
) as generation:
    # Your OpenAI call
    response = openai_client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": "Hello"}]
    )

    generation.update(
        input={"messages": [{"role": "user", "content": "Hello"}]},
        output={"content": response.choices[0].message.content},
        usage={
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens
        }
    )
```

**TypeScript:**

```typescript
import { startObservation } from "@elasticdash/tracing";

const generation = startObservation(
  "gpt-4-call",
  {
    model: "gpt-4",
    input: { messages: [{ role: "user", content: "Hello" }] }
  },
  { asType: "generation" }
);

// Your OpenAI call
const response = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "Hello" }]
});

generation.update({
  output: { content: response.choices[0].message.content },
  usage: {
    promptTokens: response.usage.prompt_tokens,
    completionTokens: response.usage.completion_tokens
  }
}).end();
```

### Nested Observations

**Python:**

```python
with elasticdash.start_as_current_observation(
    as_type="span",
    name="parent-operation"
) as parent:

    # Child observation 1
    with elasticdash.start_as_current_observation(
        as_type="span",
        name="child-1"
    ) as child1:
        child1.update(output="Child 1 complete")

    # Child observation 2
    with elasticdash.start_as_current_observation(
        as_type="generation",
        name="child-2",
        model="gpt-4"
    ) as child2:
        child2.update(output="Child 2 complete")

    parent.update(output="Parent complete")
```

**TypeScript:**

```typescript
await startActiveObservation("parent-operation", async (parent) => {

  // Child observation 1
  const child1 = startObservation("child-1", {}, { asType: "span" });
  child1.update({ output: "Child 1 complete" }).end();

  // Child observation 2
  const child2 = startObservation(
    "child-2",
    { model: "gpt-4" },
    { asType: "generation" }
  );
  child2.update({ output: "Child 2 complete" }).end();

  parent.update({ output: "Parent complete" });
});
```

### Adding Metadata and Tags

**Python:**

```python
with elasticdash.start_as_current_observation(
    as_type="span",
    name="operation",
    user_id="user-123",
    session_id="session-456",
    tags=["production", "experiment-A"],
    metadata={
        "customer_tier": "premium",
        "region": "us-east-1"
    }
) as span:
    span.update(output="Complete")
```

**TypeScript:**

```typescript
await startActiveObservation("operation", async (span) => {
  span.update({
    userId: "user-123",
    sessionId: "session-456",
    tags: ["production", "experiment-A"],
    metadata: {
      customerTier: "premium",
      region: "us-east-1"
    },
    output: "Complete"
  });
});
```

---

## Flushing Events

For short-lived applications (scripts, serverless functions), you must flush events before the process exits to ensure all traces are sent.

**Python:**

```python
from elasticdash import get_client

elasticdash = get_client()

# Your tracing code here
with elasticdash.start_as_current_observation(
    as_type="span",
    name="script-task"
) as span:
    span.update(output="Task complete")

# Flush before exit (blocks until all events sent)
elasticdash.flush()
```

**TypeScript:**

```typescript
import { sdk } from "./instrumentation";
import { startActiveObservation } from "@elasticdash/tracing";

async function main() {
  await startActiveObservation("script-task", async (span) => {
    span.update({ output: "Task complete" });
  });
}

// Shutdown before exit (flushes all events)
main().finally(() => sdk.shutdown());
```

**When to flush:**
- ✅ Scripts and CLI tools
- ✅ Serverless functions (Lambda, Cloud Functions)
- ✅ Batch jobs and cron tasks
- ❌ Long-running servers (automatic background flushing)

---

## Framework Integrations

### OpenAI SDK Integration

**Python:**

```python
from elasticdash.openai import openai

# Use the wrapped OpenAI client (drop-in replacement)
completion = openai.chat.completions.create(
    name="chat-completion",
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello"}],
    metadata={"user_id": "alice"}
)

# Automatically traced in ElasticDash!
```

**TypeScript:**

```typescript
import OpenAI from "openai";
import { observeOpenAI } from "@elasticdash/openai";

// Wrap your OpenAI client
const openai = observeOpenAI(new OpenAI());

// Use normally - automatically traced
const response = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "Hello" }]
});
```

### LangChain Integration

**Python:**

```python
from elasticdash.langchain import CallbackHandler
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate

# Initialize callback handler
elasticdash_handler = CallbackHandler()

# Use with LangChain
llm = ChatOpenAI(model_name="gpt-4")
prompt = ChatPromptTemplate.from_template("Tell me about {topic}")
chain = prompt | llm

response = chain.invoke(
    {"topic": "machine learning"},
    config={"callbacks": [elasticdash_handler]}
)
```

**TypeScript:**

```typescript
import { CallbackHandler } from "@elasticdash/langchain";
import { ChatOpenAI } from "@langchain/openai";

// Initialize callback handler
const elasticdashHandler = new CallbackHandler();

// Use with LangChain
const llm = new ChatOpenAI({ model: "gpt-4" });

const response = await llm.invoke(
  [{ role: "user", content: "Tell me about machine learning" }],
  { callbacks: [elasticdashHandler] }
);
```

---

## OpenTelemetry Foundation

ElasticDash SDKs are built on [OpenTelemetry](https://opentelemetry.io/), providing:

- **Standardization** with the observability ecosystem
- **Context propagation** for nested spans across async workloads
- **Attribute propagation** for metadata, tags, user IDs, etc.
- **Interoperability** with third-party OTel instrumentations

**Mapping:**

| OpenTelemetry | ElasticDash |
|---------------|-------------|
| OTel Trace | ElasticDash Trace |
| OTel Span | ElasticDash Observation (Span/Generation/Event) |
| Span Attributes | Trace/Observation metadata, tags, user_id |

---

## Advanced Features

### Querying Data via SDK

**Python:**

```python
from elasticdash import get_client

elasticdash = get_client()

# Fetch traces
traces = elasticdash.api.trace.list(
    user_id="user-123",
    limit=100
)

# Fetch single trace
trace = elasticdash.api.trace.get("trace-id-abc")

# Fetch observations
observations = elasticdash.api.observations_v_2.get_many(
    trace_id="trace-id-abc",
    type="GENERATION"
)
```

**TypeScript:**

```typescript
import { ElasticDashClient } from "@elasticdash/client";

const elasticdash = new ElasticDashClient();

// Fetch traces
const traces = await elasticdash.api.trace.list({
  userId: "user-123",
  limit: 100
});

// Fetch single trace
const trace = await elasticdash.api.trace.get("trace-id-abc");

// Fetch observations
const observations = await elasticdash.api.observationsV2.getMany({
  traceId: "trace-id-abc",
  type: "GENERATION"
});
```

### Custom Observation Types

**Python:**

```python
# Record an event (point in time, no duration)
with elasticdash.start_as_current_observation(
    as_type="event",
    name="cache-hit"
) as event:
    event.update(metadata={"cache_key": "user-123-query"})
```

**TypeScript:**

```typescript
// Record an event
const event = startObservation(
  "cache-hit",
  { metadata: { cacheKey: "user-123-query" } },
  { asType: "event" }
);
event.end();
```

---

## Troubleshooting

### Authentication Errors

**Problem:** SDK cannot connect to ElasticDash Logger

**Solution:**

```python
# Python: Check authentication
from elasticdash import get_client

elasticdash = get_client()
if not elasticdash.auth_check():
    print("Check your credentials and base URL")
```

### Traces Not Appearing

**Problem:** Traces not visible in Logger UI

**Solutions:**

1. **Flush events** in short-lived apps:
   ```python
   elasticdash.flush()  # Python
   ```
   ```typescript
   sdk.shutdown()  // TypeScript
   ```

2. **Check base URL** - Ensure `ELASTICDASH_BASE_URL` points to your Logger

3. **Wait 15-30 seconds** - Data may take time to process

### Import Errors (TypeScript)

**Problem:** Cannot find module `@elasticdash/tracing`

**Solution:** Ensure OpenTelemetry SDK is installed:

```bash
npm install @opentelemetry/sdk-node
```

---

## See Also

- [Data Model Reference](./data-model.md) - Understanding traces, sessions, observations
- [Fetching Data](./fetching-data.md) - Query Logger for traces and sessions
- [Architecture Overview](./architecture.md) - How ElasticDash components work together
