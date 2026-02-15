# ElasticDash Logger

<div align="center">

**Open Source LLM Observability Platform**

</div>

ElasticDash Logger is an **open source LLM observability** platform for capturing and storing execution traces from LLM applications. It is a fork of Langfuse tailored for the ElasticDash evaluation system.

> **About This Repository**: This repository contains the **ElasticDash Logger** component only. It is part of the larger ElasticDash ecosystem but can be deployed and used independently for LLM observability.

---

## ✨ Core Features

- **LLM Application Observability**: Instrument your app and start ingesting traces to ElasticDash Logger, thereby tracking LLM calls and other relevant logic in your app such as retrieval, embedding, or agent actions. Inspect and debug complex logs and user sessions.

- **Dual Database Architecture**: PostgreSQL for metadata, ClickHouse for high-volume trace data with fast analytical queries.

- **Langfuse-Compatible API**: Works with standard Langfuse SDK ecosystem and integrations.

- **OpenTelemetry Foundation**: Standards-based observability built on OpenTelemetry.

- **Async Processing**: Queue-based architecture for non-blocking trace ingestion.

- **Comprehensive API**: RESTful endpoints with OpenAPI spec for custom integrations.

---

## 📦 What This Repository Contains

This repository includes:

- **Web Application** (`/web/`) - Next.js 14 application providing:
  - REST API for trace ingestion
  - Web UI for trace visualization
  - tRPC API for internal operations

- **Worker** (`/worker/`) - Express.js background job processor for:
  - Async trace processing
  - Data aggregation
  - Queue management

- **Shared Packages** (`/packages/shared/`) - Common code including:
  - Prisma database schema (PostgreSQL)
  - ClickHouse schema and migrations
  - Shared TypeScript types and utilities

### What This Repo Is NOT

- ❌ ElasticDash Backend (evaluation engine) - separate repo
- ❌ ElasticDash Frontend (test management UI) - separate repo
- ❌ Python/JS SDKs - maintained in separate repositories

---

## 🚀 Deploy ElasticDash Logger

### Self-Host ElasticDash Logger

Run ElasticDash Logger on your own infrastructure:

#### Local (Docker Compose)

Run ElasticDash Logger on your own machine in 5 minutes using Docker Compose.

```bash
# Get a copy of the latest ElasticDash Logger repository
git clone https://github.com/your-org/ElasticDash-Logger.git
cd ElasticDash-Logger

# Run the elasticdash-logger docker compose
docker compose up
```

#### VM

Run ElasticDash Logger on a single Virtual Machine using Docker Compose.

#### Kubernetes (Helm)

Run ElasticDash Logger on a Kubernetes cluster using Helm. This is the preferred production deployment.

### Prerequisites for Local Development

- Node.js 24 (see `.nvmrc`)
- Docker and Docker Compose
- pnpm v9.5.0

### Local Development Setup

1. **Clone and install dependencies:**
   ```bash
   git clone https://github.com/your-org/ElasticDash-Logger.git
   cd ElasticDash-Logger
   pnpm install
   ```

2. **Start infrastructure:**
   ```bash
   pnpm run infra:dev:up
   ```
   This starts PostgreSQL, ClickHouse, Redis, and MinIO.

3. **Configure environment:**
   ```bash
   cp .env.dev.example .env
   # Edit .env with your configuration
   ```

4. **Run database migrations:**
   ```bash
   cd packages/shared
   pnpm run db:migrate
   ```

5. **Start the application:**
   ```bash
   # Development mode with hot reload
   pnpm run dev:web

   # Or run both web + worker
   pnpm run dev
   ```

6. **Access the Logger:**
   - Web UI: http://localhost:3000
   - API: http://localhost:3000/api/public

See **CLAUDE.md** in the repository root for detailed development instructions.

---

## 🔌 Integrations

### Main Integrations:

| Integration   | Supports                   | Description                                                                                                                                      |
|---------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| SDK           | Python, JS/TS              | Manual instrumentation using the SDKs for full flexibility.                                                                                      |
| OpenAI        | Python, JS/TS              | Automated instrumentation using drop-in replacement of OpenAI SDK.                                                                               |
| Langchain     | Python, JS/TS              | Automated instrumentation by passing callback handler to Langchain application.                                                                  |
| LlamaIndex    | Python                     | Automated instrumentation via LlamaIndex callback system.                                                                                        |
| Haystack      | Python                     | Automated instrumentation via Haystack content tracing system.                                                                                   |
| LiteLLM       | Python, JS/TS (proxy only) | Use any LLM as a drop in replacement for GPT. Use Azure, OpenAI, Cohere, Anthropic, Ollama, VLLM, Sagemaker, HuggingFace, Replicate (100+ LLMs). |
| Vercel AI SDK | JS/TS                      | TypeScript toolkit designed to help developers build AI-powered applications with React, Next.js, Vue, Svelte, Node.js.                          |
| API           | -                          | Directly call the public API. OpenAPI spec available.                                                                                            |

### Packages integrated with ElasticDash Logger:

Compatible with Instructor, DSPy, Mirascope, Ollama, Amazon Bedrock, AutoGen, Flowise, Langflow, Dify, OpenWebUI, Promptfoo, LobeChat, Vapi, and many more.

---

## 🚀 Quickstart

Instrument your app and start ingesting traces to ElasticDash Logger, thereby tracking LLM calls and other relevant logic in your app such as retrieval, embedding, or agent actions.

### 1️⃣ Create new project

1. Start ElasticDash Logger (locally or self-hosted)
2. Create a new project
3. Create new API credentials in the project settings

### 2️⃣ Install SDK

#### Python

```bash
pip install elasticdash
```

#### JavaScript/TypeScript

```bash
npm install @elasticdash/tracing @elasticdash/otel
```

### 3️⃣ Configure SDK

Set environment variables to point to your Logger instance:

```bash
ELASTICDASH_PUBLIC_KEY="pk-lf-..."
ELASTICDASH_SECRET_KEY="sk-lf-..."
ELASTICDASH_BASE_URL="http://localhost:3000"  # Your Logger URL
```

### 4️⃣ Log your first LLM call

#### Python Example

```python
from elasticdash import get_client

elasticdash = get_client()

# Create a trace with an observation
with elasticdash.start_as_current_observation(
    as_type="generation",
    name="gpt-4-call",
    model="gpt-4"
) as generation:
    generation.update(
        input={"prompt": "Hello"},
        output={"response": "Hi there!"}
    )

elasticdash.flush()  # For short-lived apps
```

#### TypeScript Example

```typescript
import { startActiveObservation } from "@elasticdash/tracing";

await startActiveObservation("gpt-4-call", async (generation) => {
  generation.update({
    model: "gpt-4",
    input: { prompt: "Hello" },
    output: { response: "Hi there!" }
  });
});
```

### 5️⃣ See traces in ElasticDash Logger

Access your Logger at http://localhost:3000 to see your language model calls and other application logic.

---

## 📚 Documentation Index

### Getting Started

1. **Architecture Overview** (`./docs/architecture.md`)
   - Logger component architecture
   - Web application and worker design
   - Database architecture (PostgreSQL + ClickHouse)
   - Data flow and processing
   - Deployment architecture

2. **SDK Overview** (`./docs/sdk-overview.md`) ⭐ Start here for instrumentation
   - Python SDK
   - JavaScript/TypeScript SDK
   - Quick start guides
   - Installation and configuration
   - Framework integrations (OpenAI, LangChain)

### Core Concepts

3. **Data Model Reference** (`./docs/data-model.md`)
   - Traces, Sessions, and Observations explained
   - Attribute tables and examples
   - Nested observation hierarchies
   - Best practices for metadata and tags

### Advanced Usage

4. **Fetching Data from Logger** (`./docs/fetching-data.md`)
   - REST API authentication and endpoints
   - Python SDK query methods
   - JavaScript/TypeScript SDK query methods
   - Common use cases and pagination
   - Performance tips

---

## 🎯 Common Use Cases

### 1. Trace a Conversation

```python
# Python example
from elasticdash import get_client

elasticdash = get_client()

with elasticdash.start_as_current_observation(
    as_type="span",
    name="chat-turn",
    session_id="session-123",
    user_id="user-alice"
) as span:
    span.update(
        input="User message",
        output="Response sent"
    )
```

### 2. Fetch Traces via API

```python
# Query via REST API
traces = elasticdash.api.trace.list(
    user_id="user-alice",
    limit=100
)
```

### 3. Analyze LLM Usage

```python
# Get generations (LLM calls)
observations = elasticdash.api.observations_v_2.get_many(
    type="GENERATION",
    from_timestamp="2026-02-01T00:00:00Z"
)
```

See **SDK Overview** (`./docs/sdk-overview.md`) for more examples.

---

## 🏗️ Architecture

### High-Level Architecture

```
User Application (instrumented with SDK)
    │
    └─► ElasticDash Logger (this repo)
            │
            ├─► Web UI (trace visualization)
            ├─► Worker (background processing)
            └─► ClickHouse Database (trace storage)
```

### Data Flow

1. **User Application** sends traces via ElasticDash SDK → HTTP POST to `/api/public/ingestion`
2. **Web Application** validates and queues the trace
3. **Worker** processes the trace asynchronously
4. **Trace** is written to both PostgreSQL (metadata) and ClickHouse (full trace data)

See **Architecture Overview** (`./docs/architecture.md`) for full details.

---

## 🤝 Contributing

Your contributions are welcome!

- Raise and comment on Issues.
- Open a PR - see CONTRIBUTING.md for details on how to setup a development environment.

---

## 🥇 License

This repository is MIT licensed, except for the `ee` folders. See LICENSE for more details.

---

## 📋 Documentation Status

This documentation covers:

✅ **ElasticDash Logger** (this repository)
✅ **SDK instrumentation** (using ElasticDash SDKs)
✅ **Data model** (Traces, Sessions, Observations)
✅ **Architecture** (Logger component design)
✅ **Querying data** (REST API and SDK methods)
✅ **Local development** (running the Logger)

⏳ **Coming soon:**
- Production deployment guide
- Kubernetes manifests
- Performance tuning guide
- Monitoring and observability

---

**Last Updated:** February 2026
