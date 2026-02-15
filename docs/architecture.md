# ElasticDash Logger Architecture

## Overview

ElasticDash Logger is an open-source LLM observability platform for capturing and storing execution traces. This document describes the architecture of **this repository** (the Logger component).

> **Note**: This documentation covers the Logger component only. For information about how the Logger integrates with other ElasticDash components (Backend, Frontend), see the main ElasticDash documentation.

## High-Level Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                  ElasticDash Logger                      │
│                     (This Repo)                          │
│                                                          │
│  ┌─────────────┐                    ┌──────────────┐   │
│  │     Web     │                    │    Worker    │   │
│  │ (Next.js 14)│                    │  (Express)   │   │
│  └──────┬──────┘                    └──────┬───────┘   │
│         │                                  │            │
│         │        ┌──────────────┐          │            │
│         ├────────│  PostgreSQL  │──────────┤            │
│         │        │  (metadata)  │          │            │
│         │        └──────────────┘          │            │
│         │                                  │            │
│         │        ┌──────────────┐          │            │
│         ├────────│  ClickHouse  │──────────┤            │
│         │        │   (traces)   │          │            │
│         │        └──────────────┘          │            │
│         │                                  │            │
│         │        ┌──────────────┐          │            │
│         └────────│     Redis    │──────────┘            │
│                  │   (queues)   │                       │
│                  └──────────────┘                       │
└─────────────────────────────────────────────────────────┘
           ▲                                    ▲
           │                                    │
    User Applications                   External Systems
    (via SDK/API)                      (queries via API)
```

---

## Component Responsibilities

### Web Application (`/web/`)

**Technology**: Next.js 14 with Pages Router, tRPC, Prisma

**Responsibilities**:
- **Trace Ingestion API**: HTTP endpoints for receiving traces from SDKs (`/api/public/ingestion`)
- **Public REST API**: Langfuse-compatible API for querying traces (`/api/public/*`)
- **Web UI**: Dashboard for trace visualization and project management
- **Authentication**: NextAuth.js for user management and API key validation
- **Internal tRPC API**: Type-safe procedures for internal operations

**Key Directories**:
- `/web/src/pages/api/public/` - REST API endpoints
- `/web/src/server/api/` - tRPC routers
- `/web/src/features/` - Feature-specific code
- `/web/src/pages/` - Next.js pages for UI

**Communication**:
- Accepts traces via HTTP POST from user applications
- Queues background jobs to Redis
- Reads/writes to PostgreSQL (metadata)
- Reads/writes to ClickHouse (trace data)

---

### Worker Application (`/worker/`)

**Technology**: Express.js, BullMQ

**Responsibilities**:
- **Async Processing**: Background jobs for trace processing
- **Queue Processing**: BullMQ consumers for various job types
- **Data Aggregation**: Computing statistics and metrics
- **Batch Operations**: Bulk data operations and cleanup

**Key Directories**:
- `/worker/src/queues/` - Queue definitions and processors
- `/worker/src/services/` - Background services

**Communication**:
- Consumes jobs from Redis queues
- Writes processed data to PostgreSQL and ClickHouse

---

### Shared Package (`/packages/shared/`)

**Responsibilities**:
- **Database Schemas**: Prisma (PostgreSQL) and ClickHouse schemas
- **Shared Types**: TypeScript types used across web and worker
- **Utilities**: Common functions and helpers
- **Migrations**: Database migration scripts

**Key Directories**:
- `/packages/shared/prisma/` - Prisma schema and migrations
- `/packages/shared/clickhouse/` - ClickHouse migrations
- `/packages/shared/src/` - Shared TypeScript code

---

## Data Flow

### 1. Trace Ingestion Flow

```text
User Application
    │ (instrumented with Langfuse SDK)
    │
    ├─► Uses OpenAI/LangChain/etc.
    │   with Langfuse tracing enabled
    │
    └─► HTTP POST /api/public/ingestion
        │
        ▼
Web Application
    │
    ├─► Validates trace format
    ├─► Authenticates API key
    └─► Queues job to Redis
        │
        ▼
Worker Application
    │
    ├─► Processes trace from queue
    ├─► Writes metadata to PostgreSQL
    └─► Writes full trace to ClickHouse
```

**Steps**:

1. Developer instruments their LLM application with Langfuse SDK
2. Application generates traces during execution (LLM calls, tool uses, etc.)
3. SDK sends traces asynchronously to ElasticDash Logger via HTTP API
4. Web application validates and queues the trace
5. Worker processes the trace in the background
6. Trace is stored in both PostgreSQL (metadata) and ClickHouse (full data)

### 2. Trace Retrieval Flow

```text
External System / User
    │
    └─► HTTP GET /api/public/traces
        │
        ▼
Web Application
    │
    ├─► Validates authentication
    ├─► Queries ClickHouse
    └─► Returns trace data (JSON)
```

**Steps**:

1. External system requests trace via REST API
2. Web application validates API key
3. Queries ClickHouse for trace data
4. Returns trace with all nested observations

### 3. Web UI Access Flow

```text
User Browser
    │
    └─► HTTP GET /
        │
        ▼
Web Application
    │
    ├─► Serves Next.js pages
    ├─► tRPC API calls for data
    ├─► Queries PostgreSQL + ClickHouse
    └─► Renders trace visualization
```

---

## Database Architecture

### Dual Database System

ElasticDash Logger uses two databases for different purposes:

#### PostgreSQL (Metadata Database)

**Purpose**: Store project configuration, users, API keys, and organizational data

**Key Tables** (from `/packages/shared/prisma/schema.prisma`):
- `Project` - Project configuration and settings
- `ApiKey` - Authentication credentials
- `User` - User accounts
- `Organization` - Organization details
- `OrganizationMembership` - User-organization relationships

**Why PostgreSQL**:
- ACID compliance for critical metadata
- Strong relational integrity
- Well-suited for configuration data

#### ClickHouse (Trace Database)

**Purpose**: Store high-volume trace data for fast querying and analytics

**Key Tables** (from `/packages/shared/clickhouse/`):
- `traces` - Trace metadata and hierarchy
- `observations` - Individual steps (spans, generations, events)
- `scores` - Evaluation scores and ratings
- `trace_sessions` - Session groupings

**Why ClickHouse**:
- Columnar storage optimized for time-series data
- Extremely fast for analytical queries
- Handles billions of rows efficiently
- Built for append-heavy workloads

### Multi-Tenancy and Security

#### Project Isolation

- Each user's traces are stored in separate projects
- Project ID is included in all ClickHouse queries for data isolation
- API keys are project-scoped

#### Authentication

**For User Applications → Logger**:

- Applications authenticate using Langfuse API keys
- HTTP Basic Auth (Public Key as username, Secret Key as password)
- API keys stored in PostgreSQL with hashed secret keys
- API keys are project-scoped

**For Web UI Users**:

- Users log in through NextAuth.js
- Session management via NextAuth
- User credentials stored in PostgreSQL

#### Security Considerations

When self-hosting:

1. **Network Isolation**: Databases should only be accessible from web/worker containers
2. **API Key Security**: Secret keys are hashed before storage
3. **HTTPS**: All external communication should use HTTPS in production
4. **Database Credentials**: Use strong passwords and restrict access by IP
5. **Environment Variables**: Never commit secrets to version control

---

## Deployment Architecture

### Development (Docker Compose)

The repository includes `docker-compose.yml` for local development:

```yaml
services:
  elasticdash-web:      # Next.js web application (port 3000)
  elasticdash-worker:   # Background worker (port 3030)
  postgres:             # PostgreSQL database (port 5432)
  clickhouse:           # ClickHouse database (ports 8123, 9000)
  redis:                # Redis for queues (port 6379)
  minio:                # MinIO for object storage (port 9000)
```

**Start with:**
```bash
pnpm run infra:dev:up    # Start infrastructure services
pnpm run dev             # Start web + worker in dev mode
```

### Production Deployment

For production, you can deploy using:

1. **Docker Images**: `elasticdash/elasticdash-web:latest` and `elasticdash/elasticdash-worker:latest`
2. **Docker Compose**: Production configuration
3. **Kubernetes**: (manifests not included in this repo)

**Required Environment Variables**:

**Web Application**:
```bash
# Database
DATABASE_URL="postgresql://user:pass@postgres:5432/langfuse"
CLICKHOUSE_URL="http://clickhouse:8123"
CLICKHOUSE_USER="clickhouse"
CLICKHOUSE_PASSWORD="password"

# Authentication
NEXTAUTH_URL="https://your-logger.com"
NEXTAUTH_SECRET="your-secret-here"
SALT="your-salt-here"
ENCRYPTION_KEY="your-encryption-key"

# Redis
REDIS_HOST="redis"
REDIS_PORT="6379"
REDIS_AUTH="redis-password"

# Storage (S3/MinIO)
ELASTICDASH_S3_EVENT_UPLOAD_BUCKET="elasticdash"
ELASTICDASH_S3_EVENT_UPLOAD_ACCESS_KEY_ID="minio"
ELASTICDASH_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY="secret"
```

**Worker Application**:
```bash
# Same as web application environment variables
# Worker shares configuration with web
```

**Infrastructure Services**:
```bash
# ClickHouse
CLICKHOUSE_DB="default"
CLICKHOUSE_USER="clickhouse"
CLICKHOUSE_PASSWORD="password"

# PostgreSQL
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres"
POSTGRES_DB="langfuse"

# Redis
# Use --requirepass flag to set password

# MinIO
MINIO_ROOT_USER="minio"
MINIO_ROOT_PASSWORD="miniosecret"
```

See `.env.dev.example` in the repository root for a complete list of configuration options.

---

## Summary

ElasticDash Logger provides:

- **Trace Ingestion**: HTTP API for receiving traces from instrumented applications
- **Trace Storage**: Dual-database architecture (PostgreSQL + ClickHouse)
- **Trace Retrieval**: REST API and Web UI for accessing stored traces
- **Background Processing**: Async worker for data processing and aggregation

**Key Architectural Decisions**:

1. **Dual Database**: PostgreSQL for metadata, ClickHouse for high-volume trace data
2. **Async Processing**: Queue-based architecture for non-blocking trace ingestion
3. **Langfuse Compatibility**: API-compatible with standard Langfuse SDKs
4. **Monorepo Structure**: Web, worker, and shared packages in single repository

This architecture allows the Logger to:

- Handle high-volume trace ingestion without blocking
- Provide fast analytical queries over trace data
- Scale horizontally by adding more worker instances
- Integrate seamlessly with the Langfuse ecosystem

## Integration with ElasticDash Ecosystem

While this repository contains only the Logger component, it integrates with:

- **ElasticDash Backend**: Queries ClickHouse directly for evaluation workflows
- **ElasticDash Frontend**: Manages test cases and displays evaluation results
- **User Applications**: Send traces via Langfuse SDKs

External systems can query traces via:
- REST API (`/api/public/*`)
- Direct ClickHouse access (read-only recommended)

---

## See Also

- [Data Model Reference](./data-model.md) - Understanding traces, sessions, and observations
- [Fetching Data from Logger](./fetching-data.md) - API methods for querying traces
- [SDK Overview](./sdk-overview.md) - Instrumenting applications to send traces
