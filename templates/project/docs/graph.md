# Project Dependency & Relationship Graph

This document is the structural wiring diagram for the codebase. It maps component hierarchies, API call paths, and database relationships to enable safe refactoring and instant blast-radius analysis.

---

## 1. System Context & Component Graph

```mermaid
graph TD
    Client[Web / Mobile Client] --> Router[API Router / Middleware]
    
    subgraph Frontend [Presentation Layer]
        Pages[Page Views] --> Components[UI Components]
        Components --> Hooks[Custom Hooks / State]
    end
    
    subgraph Backend [Application Layer]
        Router --> Controllers[API Controllers]
        Controllers --> Services[Business Services]
        Services --> DataAccess[ORM / Query Layer]
    end
    
    subgraph Storage [Data Layer]
        DataAccess --> DB[(Primary Database)]
        DataAccess --> Cache[(Redis Cache)]
    end
    
    Hooks --> Router
```

---

## 2. API Route & Call Flow Graph

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Client as Frontend View
    participant API as API Controller
    participant Service as Business Service
    participant DB as Database
    
    User->>Client: Trigger Action (e.g. Login / Submit)
    Client->>API: HTTP Request + Payload
    API->>Service: Validate & Execute Business Logic
    Service->>DB: Query / Mutation
    DB-->>Service: Result Data
    Service-->>API: Formatted Response / Token
    API-->>Client: HTTP 200 OK + JSON
    Client-->>User: Update UI State
```

---

## 3. Database Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    USERS ||--o{ PROJECTS : owns
    PROJECTS ||--o{ TASKS : contains
    USERS ||--o{ SESSIONS : has
    
    USERS {
        string id PK
        string email UK
        string password_hash
        datetime created_at
    }
    PROJECTS {
        string id PK
        string user_id FK
        string name
        string status
    }
    TASKS {
        string id PK
        string project_id FK
        string title
        boolean completed
    }
    SESSIONS {
        string id PK
        string user_id FK
        string token
        datetime expires_at
    }
```

---

## 4. Blast Radius & Dependency Matrix

Use this table to check downstream impacts before modifying core shared modules:

| Core Module / File | Direct Dependents (Imported By) | Risk Level | Blast Radius Mitigation |
| --- | --- | :---: | --- |
| `src/db/schema.ts` | All Services, Migrations, Models | **HIGH** | Run typecheck & full test suite on schema edit. |
| `src/middleware/auth.ts` | All Protected API Routes | **HIGH** | Verify token expiration & authorization test cases. |
| `src/components/ui/Button.tsx` | All Page Views, Modal Dialogs | **MEDIUM** | Check visual styling & disabled states. |
| `src/utils/formatters.ts` | Dashboard, Table Components | **LOW** | Unit test input/output edge cases. |
