# FAF Cab Management Platform

## Overview

The FAF Cab Management Platform is a comprehensive microservices-based system designed to manage various aspects of facility operations, including user management, resource sharing, booking systems, and financial tracking.

## Service Architecture

### Core Services

| Service                 | Base Path                  | Description                                                |
| ----------------------- |----------------------------| ---------------------------------------------------------- |
| Gateway Service         | `/api/v1`                  | User authentication and caching (entry point for clients)  |
| Message Broker          | `/api/v1`                  | Service-to-service communication, routing, load balancing |
| Service Discovery       | `/eureka`                  | Service registration and discovery (Eureka)               |
| Data Warehouse          | `/warehouse/api/v1`         | Centralized data warehouse with ETL processing            |
| User Management Service | `/userservicesvc/api/v1`   | User authentication, authorization, and profile management |
| Notification Service    | `/notificationsvc/api/v1`  | Multi-channel notification delivery system                 |
| Communication Service   | `/communicationsvc/api/v1` | Real-time messaging and chat functionality                 |
| Lost & Found Service    | `/lostfoundsvc/api/v1`     | Item tracking and resolution management                    |
| Fund Raising Service    | `/fundraisingsvc/api/v1`   | Campaign management and donation processing                |
| Sharing Service         | `/sharingsvc/api/v1`       | Resource lending and tracking system                       |
| Budgeting Service       | `/budgetingsvc/api/v1`     | Financial ledger and transaction management                |
| Cab Booking Service     | `/cabbookingsvc/api/v1`    | Room and facility booking system                           |
| Check-in Service        | `/checkinsvc/api/v1`       | Access control and attendance tracking                     |
| Tea Management Service  | `/teasvc/api/v1`           | Inventory management for consumables                       |


### Docker Hub
| Service                 | Docker Hub Url                                                                  |
| ----------------------- |---------------------------------------------------------------------------------|
| Gateway Service         | `https://hub.docker.com/repository/docker/smeloved/pad-gateway-svc`            |
| Message Broker          | `https://hub.docker.com/repository/docker/nidelcue/pad-message-broker`          |
| Service Discovery       | `https://hub.docker.com/repository/docker/nidelcue/pad-discovery-svc`          |
| Data Warehouse          | `https://hub.docker.com/repository/docker/pad-labs/pad-data-warehouse`         |
| User Management Service | `https://hub.docker.com/repository/docker/laineer/pad-user-svc`                 |
| Notification Service    | `https://hub.docker.com/repository/docker/laineer/pad-notification-svc`         |
| Communication Service   | `https://hub.docker.com/repository/docker/smeloved/pad-communication-svc`       |
| Lost & Found Service    | `https://hub.docker.com/repository/docker/mithancik/pad-lost-and-found-service` |
| Fund Raising Service    | `https://hub.docker.com/repository/docker/nidelcue/fund-raising-svc`            |
| Sharing Service         | `https://hub.docker.com/repository/docker/nidelcue/pad-sharing-svc`             |
| Budgeting Service       | `https://hub.docker.com/repository/docker/mithancik/pad-budgeting-service`      |
| Cab Booking Service     | `https://hub.docker.com/repository/docker/kira9999/cab-booking-service`         |
| Check-in Service        | `https://hub.docker.com/repository/docker/kira9999/check-in-service/general`    |
| Tea Management Service  | `https://hub.docker.com/repository/docker/smeloved/pad-tea-svc`                 |

### External Integrations

- **Google Calendar** - Event synchronization
- **Discord** - Communication platform integration

---

## Service Boundaries and Communication

The FAF Cab Management Platform is built using a **microservices architecture**, where each service encapsulates a specific functionality. This ensures **modularity, independence, and maintainability**.

**All service-to-service communication flows through the Message Broker**, which provides routing, load balancing, circuit breaking, and reliable message delivery. The Gateway Service handles only user authentication and caching, routing authenticated requests to backend services via the Message Broker.

### Infrastructure Services

#### Gateway Service

- **Responsibilities:**
  - User authentication (Discord OAuth2, JWT validation)
  - Response caching for authenticated requests with **Consistent Hashing-based sharding**
  - Request routing to backend services via Message Broker
  - **Saga transaction coordination** for long-running distributed transactions
- **Technology:** **Java (Spring Boot + Redis Cluster)**
- **Caching Architecture:**
  - **Consistent Hashing** for cache sharding across multiple Redis nodes
  - Automatic key distribution using hash ring (virtual nodes for better distribution)
  - Minimal key redistribution when nodes are added/removed (only ~1/n keys move)
  - Comparison with Redis Cluster:
    - **Custom Consistent Hashing:** More control over sharding logic, can customize hash function and virtual nodes
    - **Redis Cluster:** Built-in sharding, automatic failover, but less flexible for custom distribution strategies
    - **Our Implementation:** Uses consistent hashing for predictable key placement and minimal reshuffling
- **Communication Pattern:** 
  - Receives user requests and validates authentication
  - Routes service requests through Message Broker using subscriber-based queues
  - Caches responses with sharded storage for improved performance and scalability
  - Coordinates Saga transactions for distributed operations
- **Note:** All service-to-service routing, load balancing, and circuit breaking has been moved to the Message Broker.

#### Message Broker

- **Responsibilities:**
  - Service-to-service communication routing
  - Load balancing across service instances
  - Circuit breaker implementation for fault tolerance
  - Subscriber-based queues for Gateway-to-Service communication
  - Topic-based queues for Service-to-Service event-driven communication
  - Durable message queues with persistence
  - Dead Letter Channel for failed messages
  - Service high availability (automatic failover to healthy instances)
  - **Saga transaction coordination** for long-running distributed transactions (replaces 2PC)
  - Thread-per-Request architecture for concurrent request handling
- **Technology:** **Go** – chosen for high-performance concurrent message processing and efficient resource utilization
- **Communication Patterns:**
  - **gRPC** for Service-to-Service synchronous communication (reduces overhead compared to REST)
  - **WebSocket** for real-time message delivery and service subscriptions
  - **HTTP REST** for Gateway routing and administrative endpoints
- **Features:**
  - **Subscriber-based queues:** Gateway knows which services to route requests to
  - **Topic-based queues:** Services publish events without knowing subscribers (pub/sub pattern)
  - **Load Balancing:** Round-robin distribution across healthy service instances
  - **Circuit Breakers:** Automatic failure detection and request blocking for unhealthy services
  - **Service High Availability:** Automatic rerouting to healthy instances when circuit breaker trips
  - **Durable Queues:** Messages persisted to disk for reliability
  - **Dead Letter Channel:** Failed messages after retries are moved to DLQ for manual inspection
  - **Saga Transactions:** Orchestrates long-running distributed transactions with compensation logic
    - **Saga Pattern:** Each step has a compensating action for rollback
    - **Coordinator:** Gateway/Message Broker coordinates saga execution
    - **Benefits over 2PC:** Better suited for long-running transactions, no blocking locks, eventual consistency
- **Service Registration:** Services register with Service Discovery (Eureka) and include their subscribed topics in metadata

#### Service Discovery

- **Responsibilities:**
  - Service registration and health monitoring
  - Service instance discovery for load balancing
  - Metadata management (including topic subscriptions)
- **Technology:** **Java (Spring Cloud Eureka)**
- **Communication Pattern:** REST API for service registration and discovery

#### Data Warehouse

- **Responsibilities:**
  - Centralized data storage for analytics and reporting
  - Periodic ETL (Extract, Transform, Load) processing from all service databases
  - Data aggregation and denormalization for analytical queries
  - Historical data retention for trend analysis
- **Technology:** **PostgreSQL** (warehouse database) + **ETL Service** (Python/Java)
- **ETL Process:**
  - **Extract:** Periodically extracts data from all service databases (PostgreSQL and MongoDB)
  - **Transform:** Normalizes, aggregates, and enriches data for analytical purposes
  - **Load:** Loads transformed data into warehouse schema
  - **Schedule:** Runs periodically (configurable, e.g., hourly, daily)
  - **Incremental Updates:** Tracks last sync timestamp to only process new/changed data
- **Data Sources:**
  - User Management Service (PostgreSQL)
  - Budgeting Service (PostgreSQL)
  - Fund Raising Service (PostgreSQL)
  - Sharing Service (PostgreSQL)
  - Tea Management Service (PostgreSQL)
  - Cab Booking Service (PostgreSQL)
  - Lost & Found Service (PostgreSQL)
  - Communication Service (MongoDB)
  - Check-in Service (MongoDB)
  - Notification Service (MongoDB)
- **Warehouse Schema:**
  - Denormalized fact tables for analytical queries
  - Dimension tables for filtering and grouping
  - Time-series data for trend analysis
  - Aggregated metrics tables for dashboards
- **Communication Pattern:**
  - **ETL Job/Service:** Connects directly to service databases for extraction
  - **Message Broker:** Can receive events for near-real-time updates (optional)
  - **REST API:** Exposes warehouse data for reporting and analytics

---

### Business Services

Below is a breakdown of each business service and how it communicates with others through the Message Broker.

### 1. User Management Service

- Manages registration and user profiles (name, group, role: student, teacher, admin).
- Integrates with Discord to fetch user details from the FAF Community Server.
- **Communicates with:**
  - **Cab Booking Service** to validate bookings (via Message Broker).
  - **Lost & Found Service** for user identity on posts (via Message Broker).
  - **Communication Service** to verify users in chats (via Message Broker).
  - **Check-in Service** to confirm entries/exits (via Message Broker).
  - **Budgeting Service** for any user-related financial actions (via Message Broker).
- **Technology:** **Java (Spring Boot + PostgreSQL)**
  - Motivation: Strong type-safety and reliable relational consistency for user identity management.
- **Communication Pattern:** 
  - **gRPC** for synchronous validation requests (via Message Broker)
  - **Topic-based events** for publishing user-related events (e.g., `user.request`, `auth.event`)
  - Subscribes to topics: `user.request`, `auth.event`, `notification.status`
- **Service Discovery:** Registers with Eureka including topic subscriptions in metadata

### 2. Fund Raising Service

- Allows admins to create fundraising campaigns for items/consumables.
- Tracks donations and registers purchased objects in the appropriate services.
- Sends leftover funds to the Budgeting Service.
- **Communicates with:**
  - **Tea Management Service** to register new consumables funded through campaigns (via Message Broker).
  - **Budgeting Service** to record donations and leftover funds (via Message Broker).
- **Technology:** **Python (FastAPI + PostgreSQL)**
  - Motivation: FastAPIS provides flexibility for campaign management and donation tracking. PostgreSQL ensures ACID consistency for money flows.
- **Communication Pattern:** 
  - **Topic-based events** published to Message Broker (e.g., `fundraising.completion`, `donation.received`)
  - **gRPC** for synchronous operations when needed
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 3. Sharing Service

- Manages multi-use objects (games, cords, cups, kettles).
- Tracks borrowing/returning and item state.
- Updates the debt book if items are damaged.
- **Communicates with:**
  - **Cab Booking Service** to coordinate shared item usage during bookings (via Message Broker).
  - **Check-in Service** for tracking item usage by users entering/exiting (via Message Broker).
  - **Lost & Found Service** for reporting lost shared items (via Message Broker).
  - **Budgeting Service** to log debts for damaged items (via Message Broker).
  - **Notification Service** to alert users/owners about overdue or broken items (via Message Broker).
- **Technology:** **Python (FastAPI + PostgreSQL)**
  - Motivation: FastAPI provides lightweight APIs for object state changes. PostgreSQL ensures consistency when tracking loans/returns.
- **Communication Pattern:** 
  - **gRPC** for synchronous lookups (Cab Booking, Check-in) via Message Broker
  - **Topic-based events** for publishing item events (e.g., `item.rented`, `item.returned`, `item.created`)
  - Subscribes to relevant topics for cross-service coordination
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 4. Tea Management Service

- Tracks consumables (tea, sugar, cups, markers).
- Logs usage per user and sends alerts for overuse or low stock.
- **Communicates with:**
  - **Notification Service** for alerts to admins and users (via Message Broker).
  - **Fund Raising Service** to receive new consumables funded through campaigns (via Message Broker).
  - **Budgeting Service** to update financial records for consumables usage and purchases (via Message Broker).
- **Technology:** **Java (Spring Boot + PostgreSQL)**
  - Motivation: Strong relational integrity needed for consumables stock management.
- **Communication Pattern:** 
  - **Topic-based events** for publishing tea-related events (e.g., `tea.order`, `tea.status`)
  - **gRPC** for synchronous operations when needed
  - Subscribes to topics: `tea.order`, `tea.status`, `notification.status`
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 5. Communication Service

- Provides public and private chat functionality.
- Applies censorship and bans repeat offenders.
- **Communicates with:**
  - **Lost & Found Service** to allow user verification in posts and discussions (via Message Broker).
  - **User Management Service** to validate users in chats (via Message Broker).
  - **Check-in Service** to verify active users for chat participation (via Message Broker).
- **Technology:** **Java (Spring Boot + MongoDB)**
- **Communication Pattern:** 
  - **WebSockets** for real-time client messaging (direct to service)
  - **gRPC** for service-to-service validation requests (via Message Broker)
  - **Topic-based events** for publishing communication events (e.g., `message.request`, `user.action`)
  - Subscribes to topics: `user.action`, `notification.status`, `message.request`
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 6. Cab Booking Service

- Enables room scheduling (main room, kitchen).
- Prevents conflicts and integrates with Google Calendar.
- **Communicates with:**
  - **Check-in Service** to verify users entering/exiting the Cab (via Message Broker).
  - **User Management Service** to validate bookings (via Message Broker).
  - **Sharing Service** to coordinate shared item usage during bookings (via Message Broker).
  - **Notification Service** to alert users about booking confirmations or conflicts (via Message Broker).
- **Technology**: **Python (FastAPI + Celery + PostgreSQL)** – chosen for flexibility in handling scheduling logic and easy async job management with Celery. PostgreSQL ensures robust relational constraints to avoid double-booking.
- **Communication Pattern**: 
  - **gRPC** for synchronous validation requests (via Message Broker)
  - **Topic-based events** for publishing booking events (e.g., `booking.created`, `booking.cancelled`)
  - Subscribes to relevant topics for cross-service coordination
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 7. Check-in Service

- Tracks entry/exit of users and guests (simulated CCTV).
- Notifies admins of unknown visitors.
- **Communicates with:**
  - **Cab Booking Service** to validate user room bookings (via Message Broker).
  - **Notification Service** to alert users and admins of events (via Message Broker).
  - **Sharing Service** to track item usage by users entering/exiting (via Message Broker).
  - **User Management Service** to verify identities (via Message Broker).
- **Technology**: **Python (FastAPI + OpenCV)** – chosen for simplicity in integrating AI/ML facial recognition.
- **Communication Pattern**: 
  - **gRPC** for synchronous validation requests (via Message Broker)
  - **Topic-based events** for publishing check-in events (e.g., `checkin.entry`, `checkin.exit`)
  - Subscribes to relevant topics for cross-service coordination
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 8. Lost & Found Service

- Users can post announcements about lost/found items.
- Supports comments and resolving posts.
- **Communicates with:**
  - **Communication Service** to verify users participating in posts (via Message Broker).
  - **User Management Service** to verify user identities (via Message Broker).
  - **Notification Service** for updates on comments or resolved posts (via Message Broker).
  - **Sharing Service** for reporting lost shared items (via Message Broker).
- **Technology**: **Node.js (Express)** – chosen for lightweight, event-driven handling of posts and user interactions.
- **Communication Pattern**: 
  - **gRPC** for synchronous validation requests (via Message Broker)
  - **Topic-based events** for publishing lost & found events (e.g., `lnf.post.created`, `lnf.post.resolved`)
  - Subscribes to relevant topics for cross-service coordination
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 9. Budgeting Service

- Tracks finances: incomes, donations, expenses.
- Maintains debt book and generates CSV reports.
- **Communicates with:**
  - **Tea Management Service** to track consumable costs (via Message Broker).
  - **Sharing Service** to log debts or damages (via Message Broker).
  - **Fund Raising Service** to record donations (via Message Broker).
- **Technology**: **Node.js (NestJS)** – chosen for modularity and ability to handle financial transaction APIs.
- **Communication Pattern**: 
  - **gRPC** for synchronous finance queries (via Message Broker)
  - **Topic-based events** for publishing financial events (e.g., `debt.created`, `payment.received`)
  - Subscribes to relevant topics for cross-service coordination
  - **2 Phase Commits** for multi-database transactions (coordinated by Message Broker)
- **Service Discovery:** Registers with Eureka including topic subscriptions

### 10. Notification Service

- Sends timely alerts to users, admins, or owners.
- Acts as a **central communication hub** for alerts triggered by other services.
- **Communicates with:**
  - **Lost & Found Service** for post updates (via Message Broker).
  - **Check-in Service** for entry/exit notifications (via Message Broker).
  - **Cab Booking Service** for booking alerts (via Message Broker).
  - **Tea Management Service** for consumable usage alerts (via Message Broker).
  - **Budgeting Service** for financial updates (via Message Broker).
  - **Sharing Service** for item usage and overdue notifications (via Message Broker).
- **Technology**: **Java (Spring Boot)**
- **Communication Pattern**: 
  - **Topic-based events** for receiving notifications from various services
  - Subscribes to topics: `notification.request`, `email.send`, `sms.send`, `item.rented`, `item.returned`, `item.created`, `fundraiser.created`, `donation.received`, `fundraising.completion`
- **Service Discovery:** Registers with Eureka including topic subscriptions

---

## Communication Overview

### Architecture Pattern

The system follows a **Message Broker pattern** where:

1. **Gateway Service** handles:
   - User authentication (Discord OAuth2, JWT validation)
   - Response caching
   - Routes authenticated requests to backend services via Message Broker

2. **Message Broker** handles:
   - All service-to-service communication
   - Load balancing across service instances
   - Circuit breaking for fault tolerance
   - Service high availability (automatic failover)
   - Reliable message delivery with durable queues
   - Dead Letter Channel for failed messages
   - **Saga transaction coordination** for long-running distributed transactions

3. **Communication Patterns:**
   - **Subscriber-based queues:** Gateway-to-Service routing (Gateway knows target services)
   - **Topic-based queues:** Service-to-Service event-driven communication (pub/sub pattern)
   - **gRPC:** Service-to-Service synchronous communication (reduces overhead vs REST)
   - **WebSockets:** Real-time message delivery and service subscriptions
   - **HTTP REST:** Gateway routing and administrative endpoints

4. **Service Discovery:**
   - Services register with Eureka and include their subscribed topics in metadata
   - Message Broker uses Service Discovery to find healthy service instances
   - Load balancing automatically routes to available instances

---

### Architecture Diagram

![Architecture Diagram](https://github.com/user-attachments/assets/6dab3c08-1880-4179-991a-62f030282682)
The diagram shows services as independent modules and arrows indicate communication flows between services.

## Data Management

### Database Architecture

The platform follows a **database-per-service** pattern where each microservice owns its schema and is the only writer/reader of its database. Cross-service data access is handled through APIs (synchronous) or domain events (asynchronous).

### Storage Technologies

| Database       | Services                                                               | Use Cases                                                      | Replication Strategy |
| -------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------- | -------------------- |
| **PostgreSQL** | User, Lost & Found, Fund Raising, Tea, Sharing, Budgeting, Cab Booking | Structured data, ACID transactions, relational queries         | Master-Slave (2+ replicas) with automatic failover |
| **MongoDB**    | Communication, Check-In, Notification                                  | Unstructured data, real-time messaging, logs, flexible schemas | Replica Set (minimum 2 replicas) with automatic failover |

### Database Replication and High Availability

All database services implement **redundancy and replication** with automatic failover:

- **PostgreSQL Services:**
  - **Primary-Replica Architecture:** Each service has 1 primary and minimum 2 replica instances
  - **Streaming Replication:** Real-time WAL (Write-Ahead Log) replication
  - **Automatic Failover:** Health monitoring detects primary failures and promotes replica
  - **Read Scaling:** Read queries can be distributed across replicas
  - **Data Consistency:** Synchronous replication for critical writes, asynchronous for performance

- **MongoDB Services:**
  - **Replica Set:** Minimum 3 nodes (1 primary + 2 secondaries)
  - **Automatic Failover:** Primary election when primary node fails
  - **Read Preferences:** Configurable read distribution (primary, secondary, nearest)
  - **Write Concern:** Configurable write acknowledgment levels

- **Failover Mechanism:**
  - Health checks monitor database instances
  - Service Discovery updates available instances
  - Message Broker automatically routes to healthy database connections
  - Zero-downtime failover for read operations
  - Minimal downtime for write operations during primary promotion

### Data Consistency Model

- **Immediate user actions**: Synchronous gRPC calls via Message Broker (Gateway → Service)
- **Cross-service propagation**: Asynchronous topic-based events with durable queues
- **Distributed transactions**: **Saga pattern** coordinated by Gateway/Message Broker
  - **Saga Pattern:** Long-running transactions broken into steps with compensating actions
  - **Orchestration:** Gateway/Message Broker coordinates saga execution
  - **Compensation:** Each step has a compensating transaction for rollback
  - **Eventual Consistency:** System eventually reaches consistent state
  - **Benefits:** No blocking locks, better for long-running operations, handles partial failures gracefully
- **Audit trails**: Asynchronous event processing with idempotent consumers
- **Error handling**: Dead Letter Channel (DLC) for messages that fail after retries
- **Message persistence**: Durable queues ensure messages survive broker restarts
- **Database consistency**: Primary-replica replication with automatic failover ensures data availability

### Privacy and Data Ownership

- **PII Ownership**: User Service serves as the single source of truth for identities and roles
- **Data Minimization**: Other services store only `userId` references and minimal non-PII snapshots when necessary

## Inter-Service Interactions

### Service Dependencies and Workflows

#### Cab Booking Service

- **Validates participants** through User Service
- **Provisions access windows** via Check-In Service
- **Issues keys** through Sharing Service
- **Sends notifications** via Notification Service
- **Synchronizes events** with Google Calendar

#### Lost & Found Service

- **Returns keys** through Sharing Service
- **Restocks consumables** via Tea Service
- **Creates debts/payouts** through Budgeting Service
- **Notifies users** via Notification Service

#### Fund Raising Service

- **Processes donations** and records them in Budgeting Service
- **Triggers restocking** in Tea Service when campaigns complete

#### Check-In Service

- **Generates unknown person alerts** sent to Notification Service
- **Registers guest users** through User Service

#### Communication Service

- **Provides chat functionality** for Lost & Found and booking workflows
- **Offers content moderation** capabilities

#### Budgeting Service

- **Maintains immutable ledger** for all financial transactions
- **Tracks debts, payments, payouts, and donations**
- **Exposes balance information** to other services via Message Broker
- **Participates in Saga transactions** for multi-database operations (e.g., when resolving Lost & Found posts)
- **Database Replication:** Primary-replica setup with 2+ replicas for high availability

## API Documentation

### Service Contracts

The following sections detail the HTTP API contracts for each service, including base paths, endpoints, required headers, request/response bodies, and query parameters. All data shapes conform to the provided JSON specification.

---
## User Management Service

Base Path: `/usersvc/api/v1`

**NOTE**
- All authenticated endpoints expect header: `Authorization: Bearer <JWT>`.
- Idempotent creates require header: `X-Idempotency-Key: <unique-key>`.

---

### Endpoints

#### Authentication: Discord OAuth2 Login
- **METHOD:** GET
- **PATH:** `/auth/discord/login`
- **BEHAVIOR:** Redirects to Discord OAuth2; after success the service issues a JWT (flow-specific).

#### Get Current User (Me)
- **METHOD:** GET
- **PATH:** `/me`
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "email": "a@b.com",
  "name": "Alice",
  "roles": ["student"],
  "discordId": null,
  "createdAt": "iso",
  "enabled": true
}
```

#### Logout
- **METHOD:** POST
- **PATH:** `/logout`
- **RESPONSE:** `204 No Content`

---

#### Create User
- **METHOD:** POST
- **PATH:** `/users`
- **HEADERS:** `X-Idempotency-Key`
- **REQUEST BODY:**
```json
{
  "email": "a@b.com",
  "name": "Alice",
  "roles": ["student"],
  "discordId": null
}
```
- **RESPONSE (201):**
```json
{
  "id": "uuid",
  "email": "a@b.com",
  "name": "Alice",
  "roles": ["student"],
  "discordId": null,
  "createdAt": "iso"
}
```

#### Get User by ID
- **METHOD:** GET
- **PATH:** `/users/{id}`
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "email": "a@b.com",
  "name": "Alice",
  "roles": ["student"],
  "discordId": null,
  "createdAt": "iso",
  "enabled": true
}
```

#### List Users
- **METHOD:** GET
- **PATH:** `/users`
- **QUERY PARAMETERS:**
  - `email`  (exact match)
  - `q`      (free-text by name/email)
- **RESPONSE (200):**
```json
[
  {
    "id": "uuid",
    "email": "a@b.com",
    "name": "Alice",
    "roles": ["student"]
  }
]
```

#### Update User
- **METHOD:** PATCH
- **PATH:** `/users/{id}`
- **REQUEST BODY (standard fields):**
```json
{
  "name": "New",
  "roles": ["teacher"],
  "discordId": "12345"
}
```
- **REQUEST BODY (admin-only fields, optional):**
```json
{
  "email": "updated@example.com",
  "enabled": true
}
```
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "email": "updated@example.com",
  "name": "New",
  "roles": ["teacher"],
  "discordId": "12345",
  "enabled": true
}
```

#### Soft Delete (Disable) User
- **METHOD:** DELETE
- **PATH:** `/users/{id}`
- **AUTHZ:** ADMIN
- **BEHAVIOR:** Idempotent soft-delete/disable
- **RESPONSE:** `204 No Content`

---

#### Create Guest
- **METHOD:** POST
- **PATH:** `/guests`
- **HEADERS:** `X-Idempotency-Key`
- **REQUEST BODY (minimum):**
```json
{
  "name": "Guest John",
  "hostUserId": "uuid",
  "validUntil": "iso"
}
```
- **REQUEST BODY (optional extras, for compatibility):**
```json
{
  "faceId": "face_12345",
  "validFrom": "iso",
  "permanent": false
}
```
- **RESPONSE (201):**
```json
{
  "id": "uuid",
  "name": "Guest John",
  "roles": ["guest"],
  "hostUserId": "uuid",
  "validUntil": "iso"
}
```

#### Get Guest by ID
- **METHOD:** GET
- **PATH:** `/guests/{id}`
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "name": "Guest John",
  "roles": ["guest"],
  "hostUserId": "uuid",
  "validUntil": "iso",
  "faceId": "face_12345"
}
```

#### Generate Guest Token
- **METHOD:** POST
- **PATH:** `/guests/{id}/token`
- **RESPONSE (200):**
```json
{
  "token": "jwt",
  "expiresAt": "iso"
}
```

---

#### Send Notification
- **METHOD:** POST
- **PATH:** `/notifications`
- **HEADERS:** `X-Idempotency-Key`
- **REQUEST BODY (application/json):**
```json
{
  "recipient": {
    "userId": "uuid",
    "email": null,
    "discordId": null
  },
  "template": "CAB_BOOKED|CAB_CANCELLED|LNF_NEW|LNF_RESOLVED|DEBT_CREATED|LOW_STOCK|UNKNOWN_PERSON",
  "data": {
    "bookingId": "uuid",
    "title": "..."
  },
  "channels": ["email", "discord", "push"]
}
```
- **RESPONSE (202):**
```json
{
  "notificationId": "uuid",
  "status": "queued"
}
```

---

#### Admin: Refresh Roles from Discord
- **METHOD:** POST
- **PATH:** `/roles/refresh/{userId}`
- **AUTHZ:** ADMIN
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "roles": ["student", "moderator"],
  "refreshedAt": "iso",
  "source": "discord"
}
```
---

---
## Notification Service

Base Path: `/notificationsvc/api/v1`

### Endpoints

#### Send Notification (queue)
- **METHOD:** POST
- **PATH:** `/notifications`
- **HEADERS:** `Content-Type: application/json` *(опционально: `X-Idempotency-Key`)*
- **COMMENT:** Queue a notification (template + data) to one or more channels.
- **REQUEST BODY:**
```json
{
  "recipient": { "userId": "uuid", "email": null, "discordId": null },
  "data": { "bookingId": "uuid", "title": "..." },
  "channels": ["email", "discord", "push"]
}
```
- **RESPONSE (202):**
```json
{
  "notificationId": "uuid",
  "status": "queued"
}
```

---

#### Get Notification by ID (status)
- **METHOD:** GET
- **PATH:** `/notifications/{id}`
- **COMMENT:** Get delivery status for a previously queued notification.
- **RESPONSE (200):**
```json
{
  "notificationId": "uuid",
  "status": "queued|sent|failed",
  "lastError": null
}
```

---

#### List Notifications
- **METHOD:** GET
- **PATH:** `/notifications`
- **COMMENT:** List notifications by user. Optional filter by status.
- **QUERY PARAMETERS:**
```json
{
  "userId": "string (required)",
  "status": "PENDING|SENT|DELIVERED|READ|FAILED (optional)"
}
```
- **RESPONSE (200):**
```json
[
  {
    "id": "uuid",
    "type": "USER_REGISTERED",
    "userId": "uuid",
    "email": "user@example.com",
    "title": "You're welcome!",
    "message": "Thanks for registering.",
    "channels": ["email"],
    "status": "PENDING",
    "createdAt": "2025-09-23T00:00:00",
    "sentAt": null,
    "readAt": null
  }
]
```

---

#### Update Notification Status
- **METHOD:** PUT
- **PATH:** `/notifications/status`
- **COMMENT:** Update notification status.
- **REQUEST BODY:**
```json
{
  "notificationId": "string",
  "status": "SENT|DELIVERED|READ|FAILED"
}
```
- **RESPONSE (200):**
```json
{
  "id": "uuid",
  "status": "SENT",
  "sentAt": "2025-09-23T00:00:05",
  "readAt": null
}
```
---

## Communication Service

**Base Path:** `/commsvc/api/v1`

### Endpoints

#### Create Chat

- **POST** `/chats`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "name": "L&F: Umbrella",
    "memberIds": ["uuid", "uuid"]
  }
  ```
- **Response (201):**
  ```json
  {
    "chatId": "uuid",
    "name": "L&F: Umbrella",
    "memberIds": ["uuid", "uuid"],
    "createdAt": "iso"
  }
  ```

#### Send Message

- **POST** `/chats/{chatId}/messages`
- **Request Body:**
  ```json
  {
    "authorId": "uuid",
    "text": "Hello, I found it."
  }
  ```
- **Response (201):**
  ```json
  {
    "messageId": "uuid",
    "chatId": "uuid",
    "authorId": "uuid",
    "text": "Hello, I found it.",
    "createdAt": "iso"
  }
  ```

#### Moderate Content

- **POST** `/moderate`
- **Request Body:**
  ```json
  {
    "text": "..."
  }
  ```
- **Response (200):**
  ```json
  {
    "allowed": true,
    "reason": null
  }
  ```

---

## Lost & Found Service

**Base Path:** `/lnfsvc/api/v1`

### Endpoints

#### Create Post

- **POST** `/posts`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "type": "LOST|FOUND",
    "title": "Black umbrella",
    "description": "Left near kitchen",
    "location": "Kitchen",
    "photos": ["https://..."],
    "authorId": "uuid",
    "hints": [
      {
        "type": "sharing.item",
        "serial": "SN-123"
      }
    ],
    "notify": true
  }
  ```
- **Response (201):**
  ```json
  {
    "postId": "uuid",
    "status": "OPEN",
    "linked": {
      "sharingItemId": null,
      "teaItemId": null
    }
  }
  ```

#### List Posts

- **GET** `/posts`
- **Query Parameters:** `type`, `status`, `q`, `authorId`, `location`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "type": "FOUND",
      "title": "...",
      "status": "OPEN",
      "createdAt": "iso"
    }
  ]
  ```

#### Get Post Details

- **GET** `/posts/{postId}`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "type": "FOUND",
    "title": "...",
    "description": "...",
    "status": "OPEN",
    "authorId": "uuid",
    "createdAt": "iso"
  }
  ```

#### Add Comment

- **POST** `/posts/{postId}/comments`
- **Request Body:**
  ```json
  {
    "authorId": "uuid",
    "text": "I saw it in room 204."
  }
  ```
- **Response (201):**
  ```json
  {
    "commentId": "uuid",
    "postId": "uuid",
    "authorId": "uuid",
    "text": "I saw it in room 204.",
    "createdAt": "iso"
  }
  ```

#### Resolve Post

- **POST** `/posts/{postId}/resolve`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "resolvedBy": "uuid",
    "resolution": "RETURNED|DISCARDED|STILL_MISSING",
    "links": [
      {
        "type": "sharing.loan",
        "loanId": "uuid",
        "returnState": "OK|DAMAGED"
      },
      {
        "type": "tea.item",
        "itemId": "uuid",
        "qty": 1
      }
    ],
    "financials": {
      "chargeUserId": "uuid",
      "amount": 25,
      "currency": "USD",
      "reason": "Repair"
    },
    "reward": {
      "payToUserId": "uuid",
      "amount": 10,
      "currency": "USD"
    },
    "notify": true
  }
  ```
- **Response (200):**
  ```json
  {
    "status": "RESOLVED",
    "effects": [
      {
        "service": "sharing",
        "action": "returnLoan",
        "status": "OK"
      },
      {
        "service": "tea",
        "action": "restock",
        "status": "OK"
      },
      {
        "service": "budgeting",
        "action": "createDebt",
        "status": "OK"
      },
      {
        "service": "budgeting",
        "action": "createPayout",
        "status": "OK"
      },
      {
        "service": "notification",
        "action": "send",
        "status": "OK"
      }
    ]
  }
  ```

---

## Fund Raising Service

**Base Path:** `/frsvc/api/v1`

### Endpoints

#### Create Campaign

- **POST** `/campaigns`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "title": "Replace chess set",
    "goalAmount": 120,
    "currency": "USD",
    "createdBy": "uuid",
    "tags": ["cab", "lostfound"]
  }
  ```
- **Response (201):**
  ```json
  {
    "id": "uuid",
    "title": "Replace chess set",
    "goalAmount": 120,
    "currency": "USD",
    "status": "ACTIVE",
    "createdAt": "iso"
  }
  ```

#### List Campaigns

- **GET** `/campaigns`
- **Query Parameters:** `status`, `q`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "title": "Replace chess set",
      "status": "ACTIVE",
      "goalAmount": 120,
      "currency": "USD"
    }
  ]
  ```

#### Get Campaign Details

- **GET** `/campaigns/{id}`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "title": "Replace chess set",
    "status": "ACTIVE",
    "goalAmount": 120,
    "currency": "USD",
    "createdAt": "iso"
  }
  ```

#### Update Campaign

- **PATCH** `/campaigns/{id}`
- **Request Body:**
  ```json
  {
    "status": "PAUSED|CLOSED",
    "title": "..."
  }
  ```
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "status": "PAUSED"
  }
  ```

#### Create Donation

- **POST** `/campaigns/{id}/donations`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "donorId": "uuid",
    "amount": 25,
    "currency": "USD",
    "paymentProvider": "stripe"
  }
  ```
- **Response (201):**
  ```json
  {
    "donationId": "uuid",
    "status": "PENDING"
  }
  ```

#### Confirm Donation

- **POST** `/donations/{donationId}/confirm`
- **Response (200):**
  ```json
  {
    "donationId": "uuid",
    "status": "CONFIRMED"
  }
  ```

#### Fail Donation

- **POST** `/donations/{donationId}/fail`
- **Response (200):**

```json
{
  "donationId": "uuid",
  "status": "FAILED"
}
```

---

## Tea Management Service

**Base Path:** `/teasvc/api/v1`

### Endpoints

#### Create Item

- **POST** `/items`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "name": "Tea",
    "unit": "pcs|g|ml",
    "minLevel": 5,
    "currentLevel": 20,
    "ownerGroupId": null
  }
  ```
- **Response (201):**
  ```json
  {
    "id": "uuid",
    "name": "Tea",
    "unit": "pcs",
    "minLevel": 5,
    "currentLevel": 20,
    "ownerGroupId": null
  }
  ```

#### List Items

- **GET** `/items`
- **Query Parameters:** `lowStockOnly`, `q`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "name": "Tea",
      "unit": "pcs",
      "minLevel": 5,
      "currentLevel": 20
    }
  ]
  ```

#### Get Item Details

- **GET** `/items/{id}`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "name": "Tea",
    "unit": "pcs",
    "minLevel": 5,
    "currentLevel": 20
  }
  ```

#### Update Item

- **PATCH** `/items/{id}`
- **Request Body:**
  ```json
  {
    "minLevel": 10,
    "name": "Green Tea"
  }
  ```
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "name": "Green Tea",
    "minLevel": 10,
    "currentLevel": 20
  }
  ```

#### Use Item

- **POST** `/items/{id}/use`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "amount": 2,
    "userId": "uuid"
  }
  ```
- **Response (200):**
  ```json
  {
    "itemId": "uuid",
    "currentLevel": 18,
    "usageId": "uuid",
    "alert": "LOW_STOCK|NONE"
  }
  ```

#### Restock Items

- **POST** `/restock`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "source": "lostfound|fundraising|manual",
    "items": [
      {
        "itemId": "uuid",
        "qty": 3
      }
    ]
  }
  ```
- **Response (200):**
  ```json
  {
    "applied": true,
    "items": [
      {
        "itemId": "uuid",
        "newLevel": 21
      }
    ]
  }
  ```

#### Get Item Usage History

- **GET** `/items/{id}/usage`
- **Query Parameters:** `from`, `to`
- **Response (200):**
  ```json
  [
    {
      "usageId": "uuid",
      "userId": "uuid",
      "amount": 2,
      "createdAt": "iso"
    }
  ]
  ```

#### Get Low Stock Alerts

- **GET** `/alerts`
- **Response (200):**
  ```json
  [
    {
      "itemId": "uuid",
      "level": 3,
      "minLevel": 5
    }
  ]
  ```

---

## Sharing Service

**Base Path:** `/sharesvc/api/v1`

### Endpoints

#### Create Item

- **POST** `/items`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "name": "Key Room 204",
    "serial": "KEY-204",
    "ownerId": null,
    "notes": ""
  }
  ```
- **Response (201):**
  ```json
  {
    "id": "uuid",
    "name": "Key Room 204",
    "serial": "KEY-204",
    "state": "OK"
  }
  ```

#### List Items

- **GET** `/items`
- **Query Parameters:** `q`, `serial`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "name": "Key Room 204",
      "serial": "KEY-204",
      "state": "OK"
    }
  ]
  ```

#### Update Item

- **PATCH** `/items/{id}`
- **Request Body:**
  ```json
  {
    "name": "Key 204 (backup)",
    "notes": "engraved"
  }
  ```
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "name": "Key 204 (backup)",
    "serial": "KEY-204",
    "state": "OK"
  }
  ```

#### Loan Item

- **POST** `/items/{id}/loan`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "holderId": "uuid",
    "due": "iso|null"
  }
  ```
- **Response (201):**
  ```json
  {
    "loanId": "uuid",
    "itemId": "uuid",
    "holderId": "uuid",
    "from": "iso",
    "due": null,
    "status": "ACTIVE"
  }
  ```

#### Return Item

- **POST** `/loans/{id}/return`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "state": "OK|DAMAGED|LOST",
    "note": "..."
  }
  ```
- **Response (200):**
  ```json
  {
    "loanId": "uuid",
    "status": "RETURNED",
    "state": "DAMAGED"
  }
  ```

#### List Loans

- **GET** `/loans`
- **Query Parameters:** `status`, `userId`, `itemId`
- **Response (200):**
  ```json
  [
    {
      "loanId": "uuid",
      "itemId": "uuid",
      "holderId": "uuid",
      "status": "ACTIVE",
      "due": "iso"
    }
  ]
  ```

---

## Budgeting Service

**Base Path:** `/budgsvc/api/v1`

### Endpoints

#### Get User Balance

- **GET** `/balances/{userId}`
- **Response (200):**
  ```json
  {
    "userId": "uuid",
    "currency": "USD",
    "balance": -25.0
  }
  ```

#### Create Debt

- **POST** `/debts`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "source": "lostfound|sharing|tea|cab",
    "refId": "entityId",
    "userId": "uuid",
    "amount": 25.0,
    "currency": "USD",
    "reason": "Repair"
  }
  ```
- **Response (201):**
  ```json
  {
    "debtId": "uuid",
    "status": "OPEN"
  }
  ```

#### List Debts

- **GET** `/debts`
- **Query Parameters:** `userId`, `status`
- **Response (200):**
  ```json
  [
    {
      "debtId": "uuid",
      "userId": "uuid",
      "amount": 25.0,
      "currency": "USD",
      "status": "OPEN"
    }
  ]
  ```

#### Get Debt Details

- **GET** `/debts/{id}`
- **Response (200):**
  ```json
  {
    "debtId": "uuid",
    "userId": "uuid",
    "amount": 25.0,
    "currency": "USD",
    "status": "OPEN"
  }
  ```

#### Record Payment

- **POST** `/payments`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "debtId": "uuid",
    "amount": 25.0,
    "currency": "USD",
    "paidBy": "uuid",
    "method": "cash|transfer",
    "at": "iso"
  }
  ```
- **Response (201):**
  ```json
  {
    "paymentId": "uuid",
    "debtId": "uuid",
    "newStatus": "CLOSED|OPEN"
  }
  ```

#### Create Payout

- **POST** `/payouts`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "source": "lostfound",
    "refId": "postId",
    "userId": "finderId",
    "amount": 10,
    "currency": "USD",
    "reason": "Finder reward"
  }
  ```
- **Response (201):**
  ```json
  {
    "payoutId": "uuid"
  }
  ```

#### Record Donation

- **POST** `/donations`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "donationId": "uuid",
    "campaignId": "uuid",
    "donorId": "uuid",
    "amount": 50,
    "currency": "USD",
    "receivedAt": "iso"
  }
  ```
- **Response (201):**
  ```json
  {
    "ledgerEntryId": "uuid"
  }
  ```

---

## Check-In Service

**Base Path:** `/checkinsvc/api/v1`

### Endpoints

#### Record Face Event

- **POST** `/events/face`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "direction": "IN|OUT",
    "cameraId": "cam-1",
    "faceHash": "...",
    "screenshotUrl": "https://..."
  }
  ```
- **Response (200):**
  ```json
  {
    "checkId": "uuid",
    "matchedUserId": "uuid|null",
    "status": "KNOWN|UNKNOWN",
    "timestamp": "iso"
  }
  ```

#### List Check Events

- **GET** `/checks`
- **Query Parameters:** `from`, `to`, `userId`, `cameraId`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "userId": "uuid|null",
      "direction": "IN",
      "timestamp": "iso",
      "cameraId": "cam-1"
    }
  ]
  ```

#### List Alerts

- **GET** `/alerts`
- **Query Parameters:** `status`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "type": "UNKNOWN_PERSON",
      "status": "OPEN",
      "createdAt": "iso"
    }
  ]
  ```

#### Acknowledge Alert

- **POST** `/alerts/{id}/ack`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "status": "ACK"
  }
  ```

#### Close Alert

- **POST** `/alerts/{id}/close`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "status": "CLOSED"
  }
  ```

#### Create Access Window

- **POST** `/access-windows`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "roomId": "204",
    "start": "iso",
    "end": "iso",
    "participantIds": ["uuid", "uuid"]
  }
  ```
- **Response (201):**
  ```json
  {
    "accessWindowId": "uuid",
    "roomId": "204",
    "start": "iso",
    "end": "iso"
  }
  ```

#### Delete Access Window

- **DELETE** `/access-windows/{id}`
- **Response (204):** No content

#### Issue Key

- **POST** `/keys/issue`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "keyItemId": "uuid",
    "holderId": "uuid",
    "due": "iso|null"
  }
  ```
- **Response (201):**
  ```json
  {
    "loanId": "uuid",
    "status": "ACTIVE"
  }
  ```

#### Return Key

- **POST** `/keys/{loanId}/return`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "state": "OK|DAMAGED|LOST"
  }
  ```
- **Response (200):**
  ```json
  {
    "loanId": "uuid",
    "status": "RETURNED",
    "state": "OK"
  }
  ```

---

## Cab Booking Service

**Base Path:** `/cabsvc/api/v1`

### Endpoints

#### Create Booking

- **POST** `/bookings`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "roomId": "204",
    "title": "Study group",
    "start": "2025-09-10T14:00:00Z",
    "end": "2025-09-10T15:00:00Z",
    "createdBy": "uuid",
    "participants": ["uuid", "uuid"],
    "notify": true
  }
  ```
- **Response (201):**
  ```json
  {
    "id": "uuid",
    "roomId": "204",
    "title": "Study group",
    "start": "iso",
    "end": "iso",
    "status": "CONFIRMED",
    "gcalEventId": "abc123"
  }
  ```

#### List Bookings

- **GET** `/bookings`
- **Query Parameters:** `roomId`, `from`, `to`, `participantId`
- **Response (200):**
  ```json
  [
    {
      "id": "uuid",
      "roomId": "204",
      "title": "Study group",
      "start": "iso",
      "end": "iso",
      "status": "CONFIRMED"
    }
  ]
  ```

#### Get Booking Details

- **GET** `/bookings/{id}`
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "roomId": "204",
    "title": "Study group",
    "start": "iso",
    "end": "iso",
    "status": "CONFIRMED"
  }
  ```

#### Update Booking

- **PATCH** `/bookings/{id}`
- **Request Body:**
  ```json
  {
    "title": "New title",
    "start": "iso",
    "end": "iso",
    "participants": ["uuid"]
  }
  ```
- **Response (200):**
  ```json
  {
    "id": "uuid",
    "status": "CONFIRMED"
  }
  ```

#### Delete Booking

- **DELETE** `/bookings/{id}`
- **Response (204):** No content

#### Provision Access

- **POST** `/bookings/{id}/provision-access`
- **Response (200):**
  ```json
  {
    "accessWindowId": "uuid"
  }
  ```

#### Issue Key

- **POST** `/bookings/{id}/issue-key`
- **Headers:** `X-Idempotency-Key`
- **Request Body:**
  ```json
  {
    "keyItemId": "uuid"
  }
  ```
- **Response (201):**
  ```json
  {
    "loanId": "uuid"
  }
  ```

---

## Message Broker API Documentation

**Base Path:** `/api/v1`

### Endpoints

#### Health Check
- **METHOD:** GET
- **PATH:** `/health`
- **RESPONSE (200):**
```json
{
  "status": "healthy",
  "broker": "broker-prod-1"
}
```

#### Route Request (Gateway-to-Service)
- **METHOD:** POST
- **PATH:** `/api/v1/route`
- **DESCRIPTION:** Gateway uses this endpoint to route requests to backend services
- **REQUEST BODY:**
```json
{
  "service": "user-service",
  "method": "GET",
  "path": "/users/{id}",
  "headers": {
    "Authorization": "Bearer <JWT>"
  },
  "body": null,
  "requestId": "uuid"
}
```
- **RESPONSE (200):**
```json
{
  "requestId": "uuid",
  "statusCode": 200,
  "headers": {},
  "body": {},
  "error": null
}
```
- **FEATURES:**
  - Automatic load balancing across service instances
  - Circuit breaker protection
  - Automatic failover to healthy instances
  - Request timeout handling

#### List Available Topics
- **METHOD:** GET
- **PATH:** `/api/v1/topics`
- **DESCRIPTION:** Returns list of all topics available in the Message Broker
- **RESPONSE (200):**
```json
{
  "topics": [
    {
      "name": "user.request",
      "subscribers": 2,
      "messagesInQueue": 5
    },
    {
      "name": "notification.status",
      "subscribers": 3,
      "messagesInQueue": 12
    }
  ]
}
```

#### List Dead Letter Channel Messages
- **METHOD:** GET
- **PATH:** `/api/v1/dlq`
- **DESCRIPTION:** Returns messages in the Dead Letter Channel
- **QUERY PARAMETERS:**
  - `limit` (optional, default: 100)
  - `offset` (optional, default: 0)
- **RESPONSE (200):**
```json
{
  "messages": [
    {
      "id": "uuid",
      "topic": "notification.request",
      "payload": {},
      "error": "Max retries exceeded",
      "retries": 5,
      "timestamp": "2025-01-15T10:30:00Z",
      "originalService": "lost-found-service"
    }
  ],
  "total": 15,
  "limit": 100,
  "offset": 0
}
```

### WebSocket Endpoint

#### Service Connection
- **PATH:** `/ws/service`
- **DESCRIPTION:** Services connect via WebSocket to receive messages
- **PROTOCOL:** WebSocket
- **MESSAGE FORMAT:**
```json
{
  "type": "subscribe|publish|ack",
  "topic": "notification.request",
  "payload": {},
  "messageId": "uuid"
}
```

### gRPC Service

- **PORT:** 9090 (default)
- **SERVICE:** `MessageBroker`
- **METHODS:**
  - `PublishMessage(topic, payload)` - Publish message to topic
  - `SubscribeToTopic(topic)` - Subscribe to topic
  - `RouteRequest(service, method, path, headers, body)` - Route request to service
  - `StartSaga(sagaId, steps)` - Start a new saga transaction
  - `ExecuteSagaStep(sagaId, stepId, payload)` - Execute a saga step
  - `CompensateSagaStep(sagaId, stepId)` - Compensate a saga step
  - `GetSagaStatus(sagaId)` - Get saga transaction status

---

## Gateway Service API Documentation

**Base Path:** `/api/v1`

### Endpoints

#### Health Check
- **METHOD:** GET
- **PATH:** `/health`
- **RESPONSE (200):**
```json
{
  "status": "healthy",
  "cache": {
    "nodes": 3,
    "sharding": "consistent-hashing"
  }
}
```

#### Start Saga Transaction
- **METHOD:** POST
- **PATH:** `/api/v1/saga/start`
- **DESCRIPTION:** Initiates a long-running saga transaction
- **REQUEST BODY:**
```json
{
  "sagaId": "uuid",
  "steps": [
    {
      "stepId": "step-1",
      "service": "sharing-service",
      "action": "loanItem",
      "payload": {
        "itemId": "uuid",
        "holderId": "uuid"
      },
      "compensation": {
        "action": "returnItem",
        "payload": {}
      }
    },
    {
      "stepId": "step-2",
      "service": "budgeting-service",
      "action": "createDebt",
      "payload": {
        "userId": "uuid",
        "amount": 25.0
      },
      "compensation": {
        "action": "cancelDebt",
        "payload": {}
      }
    }
  ]
}
```
- **RESPONSE (202):**
```json
{
  "sagaId": "uuid",
  "status": "STARTED",
  "startedAt": "2025-01-15T10:30:00Z"
}
```

#### Get Saga Status
- **METHOD:** GET
- **PATH:** `/api/v1/saga/{sagaId}/status`
- **RESPONSE (200):**
```json
{
  "sagaId": "uuid",
  "status": "IN_PROGRESS|COMPLETED|FAILED|COMPENSATING",
  "currentStep": "step-2",
  "completedSteps": ["step-1"],
  "failedSteps": [],
  "startedAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:31:00Z"
}
```

#### Cache Sharding Information
- **METHOD:** GET
- **PATH:** `/api/v1/cache/sharding`
- **DESCRIPTION:** Returns information about cache sharding configuration
- **RESPONSE (200):**
```json
{
  "algorithm": "consistent-hashing",
  "nodes": [
    {
      "id": "redis-node-1",
      "host": "redis-1:6379",
      "virtualNodes": 150,
      "keys": 1250
    },
    {
      "id": "redis-node-2",
      "host": "redis-2:6379",
      "virtualNodes": 150,
      "keys": 1180
    },
    {
      "id": "redis-node-3",
      "host": "redis-3:6379",
      "virtualNodes": 150,
      "keys": 1220
    }
  ],
  "totalKeys": 3650,
  "hashFunction": "sha256"
}
```

---

## Data Warehouse API Documentation

**Base Path:** `/warehouse/api/v1`

### Endpoints

#### Health Check
- **METHOD:** GET
- **PATH:** `/health`
- **RESPONSE (200):**
```json
{
  "status": "healthy",
  "lastETLRun": "2025-01-15T09:00:00Z",
  "nextETLRun": "2025-01-15T10:00:00Z"
}
```

#### Trigger ETL Job
- **METHOD:** POST
- **PATH:** `/etl/trigger`
- **DESCRIPTION:** Manually trigger ETL job execution
- **REQUEST BODY (optional):**
```json
{
  "incremental": true,
  "since": "2025-01-15T08:00:00Z",
  "services": ["user-service", "budgeting-service"]
}
```
- **RESPONSE (202):**
```json
{
  "jobId": "uuid",
  "status": "STARTED",
  "startedAt": "2025-01-15T10:30:00Z"
}
```

#### Get ETL Job Status
- **METHOD:** GET
- **PATH:** `/etl/jobs/{jobId}`
- **RESPONSE (200):**
```json
{
  "jobId": "uuid",
  "status": "RUNNING|COMPLETED|FAILED",
  "progress": {
    "totalServices": 10,
    "processedServices": 7,
    "recordsProcessed": 15420,
    "recordsFailed": 0
  },
  "startedAt": "2025-01-15T10:30:00Z",
  "completedAt": null,
  "error": null
}
```

#### Query Warehouse Data
- **METHOD:** POST
- **PATH:** `/query`
- **DESCRIPTION:** Execute analytical queries on warehouse data
- **REQUEST BODY:**
```json
{
  "query": "SELECT service_name, COUNT(*) as total_events, DATE(created_at) as date FROM events WHERE created_at >= '2025-01-01' GROUP BY service_name, DATE(created_at)",
  "format": "json|csv"
}
```
- **RESPONSE (200):**
```json
{
  "results": [
    {
      "service_name": "user-service",
      "total_events": 1250,
      "date": "2025-01-15"
    }
  ],
  "rowCount": 1,
  "executionTime": "0.045s"
}
```

#### Get Warehouse Schema
- **METHOD:** GET
- **PATH:** `/schema`
- **DESCRIPTION:** Returns warehouse schema information
- **RESPONSE (200):**
```json
{
  "tables": [
    {
      "name": "users_fact",
      "columns": ["user_id", "email", "name", "roles", "created_at", "updated_at"],
      "source": "user-service",
      "lastUpdated": "2025-01-15T09:00:00Z"
    },
    {
      "name": "transactions_fact",
      "columns": ["transaction_id", "user_id", "amount", "type", "created_at"],
      "source": "budgeting-service",
      "lastUpdated": "2025-01-15T09:00:00Z"
    }
  ]
}
```

#### Get ETL Statistics
- **METHOD:** GET
- **PATH:** `/etl/statistics`
- **DESCRIPTION:** Returns ETL processing statistics
- **RESPONSE (200):**
```json
{
  "lastRun": "2025-01-15T09:00:00Z",
  "nextRun": "2025-01-15T10:00:00Z",
  "totalRuns": 1245,
  "successfulRuns": 1240,
  "failedRuns": 5,
  "averageDuration": "45.2s",
  "servicesProcessed": 10,
  "totalRecordsProcessed": 1250000
}
```

---

## Architecture Enhancements

### Consistent Hashing for Cache Sharding

The Gateway Service implements **Consistent Hashing** for distributed cache sharding:

- **Hash Ring:** Cache keys are mapped to a hash ring using SHA-256
- **Virtual Nodes:** Each Redis node has 150 virtual nodes for better distribution
- **Key Distribution:** Keys are distributed evenly across shards
- **Node Addition/Removal:** Only ~1/n keys need to be redistributed when nodes change
- **Comparison with Redis Cluster:**
  - **Custom Consistent Hashing:** More control, predictable key placement, customizable hash function
  - **Redis Cluster:** Built-in sharding, automatic failover, but less flexible
  - **Our Choice:** Custom implementation for fine-grained control and minimal reshuffling

### Database Replication and Failover

All database services implement high availability:

- **PostgreSQL:** Primary-Replica with streaming replication (2+ replicas)
- **MongoDB:** Replica Sets with automatic primary election (3+ nodes)
- **Failover:** Automatic promotion of replicas when primary fails
- **Read Scaling:** Read queries distributed across replicas
- **Zero Downtime:** Minimal service interruption during failover

### Data Warehouse and ETL

- **Centralized Warehouse:** PostgreSQL database aggregating data from all services
- **ETL Process:** Periodic extraction, transformation, and loading
- **Incremental Updates:** Only processes new/changed data since last run
- **Analytical Queries:** Denormalized schema optimized for reporting
- **Schedule:** Configurable (hourly/daily) with manual trigger option

### Saga Transactions

Replaces 2 Phase Commits with **Saga pattern** for long-running transactions:

- **Orchestration:** Gateway/Message Broker coordinates saga execution
- **Compensation:** Each step has a compensating action for rollback
- **Eventual Consistency:** System eventually reaches consistent state
- **Benefits:** No blocking locks, handles partial failures, better for long operations

---

## Development Guidelines

### Branching & Commits Policy

#### Branches

**Feature Branches:**

- **Name:** `feat/<name_of_feature>` (iterations: `feat/<name_of_feature>/v2`, `/v3`, …)
- **Always branch from dev:**
  ```bash
  git checkout dev && git pull
  git checkout -b feat/<name_of_feature>
  ```
- **main is release-only** — code gets there only via Pull Request
- **After merging a feature into dev, delete the branch** (local + remote)

#### Merge Strategy

- **Feature → dev:** Squash & Merge via Pull Request
- **dev → main:** Pull Request only (after review/CI)

#### Pull Requests

**Title Format:**

- `feat: <feature name>`
- `fix: <short issue>`

**Requirements:**

- Include brief summary
- Link related issues
- Update docs/contracts if APIs changed
- CI must pass before merge
- **only 1 approval required** for merging
- Use squash merge strategy
