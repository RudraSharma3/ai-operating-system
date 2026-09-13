# Architecture

This document is the durable source of truth for the project's technical architecture.

---

## 1. System Purpose & Scope

<!-- What does this project do? Who are the primary users? What problem does it solve? -->

## 2. System Context & Boundaries

<!-- Diagram or description of external systems, client applications, APIs, third-party services, and trust boundaries. -->

## 3. Component Architecture & Module Responsibilities

<!-- Key subsystems, packages, directories, and their specific responsibilities. -->
- `src/` - Primary source code
  - `controllers/` / `routes/` - API endpoints and request handling
  - `services/` - Core business logic
  - `models/` / `db/` - Data structures and persistence layer
- `tests/` - Automated unit, integration, and regression suites

## 4. Data Flow & State Management

<!-- How data moves through the application during standard workflows. Caching, storage, and synchronization mechanisms. -->

## 5. Security & Trust Boundaries

<!-- Authentication, authorization, data encryption at rest/transit, secret management, PII handling, and input validation. -->

## 6. Operational Runbook & Deployment

<!-- Runtime environments, environment variables, monitoring/telemetry, CI/CD pipeline, and disaster recovery procedures. -->
