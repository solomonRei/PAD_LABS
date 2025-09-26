# FAF Cab Management Platform

## Overview

The FAF Cab Management Platform is a comprehensive microservices-based system designed to manage various aspects of facility operations, including user management, resource sharing, booking systems, and financial tracking.

## Service Architecture

### Core Services

| Service                 | Base Path                  | Description                                                |
| ----------------------- |----------------------------| ---------------------------------------------------------- |
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
| User Management Service | `https://hub.docker.com/repository/docker/laineer/pad-user-svc`                 |
| Notification Service    | `https://hub.docker.com/repository/docker/laineer/pad-notification-svc`         |
| Communication Service   | `https://hub.docker.com/repository/docker/smeloved/pad-communication-svc`       |
| Lost & Found Service    | `https://hub.docker.com/repository/docker/mithancik/pad-lost-and-found-service` |
| Fund Raising Service    | `https://hub.docker.com/repository/docker/nidelcue/fund-raising-svc`            |
| Sharing Service         | `https://hub.docker.com/repository/docker/nidelcue/pad-sharing-svc`             |
| Budgeting Service       | `https://hub.docker.com/repository/docker/mithancik/pad-budgeting-service`      |
| Cab Booking Service     |                                                                                 |
| Check-in Service        |                                                                                 |
| Tea Management Service  | `https://hub.docker.com/repository/docker/smeloved/pad-tea-svc`                 |

### External Integrations

- **Google Calendar** - Event synchronization
- **Discord** - Communication platform integration

---

## Service Boundaries and Communication

The FAF Cab Management Platform is built using a **microservices architecture**, where each service encapsulates a specific functionality. This ensures **modularity, independence, and maintainability**.

Some services interact to share data or trigger actions, typically via **notifications, API calls, or shared databases**. Below is a breakdown of each service and how it communicates with others.

### 1. User Management Service

- Manages registration and user profiles (name, group, role: student, teacher, admin).
- Integrates with Discord to fetch user details from the FAF Community Server.
- **Communicates with:**
  - **Cab Booking Service** to validate bookings.
  - **Lost & Found Service** for user identity on posts.
  - **Communication Service** to verify users in chats.
  - **Check-in Service** to confirm entries/exits.
  - **Budgeting Service** for any user-related financial actions.
- **Technology:** **Java (Spring Boot + PostgreSQL)**
  - Motivation: Strong type-safety and reliable relational consistency for user identity management.
- **Communication Pattern:** **REST API** for synchronous validation with Booking, Lost & Found, Communication, and Check-in.
  - Trade-off: REST is simple and universal, though not as fast as event-driven systems. It is still ideal for identity checks.

### 2. Fund Raising Service

- Allows admins to create fundraising campaigns for items/consumables.
- Tracks donations and registers purchased objects in the appropriate services.
- Sends leftover funds to the Budgeting Service.
- **Communicates with:**
  - **Tea Management Service** to register new consumables funded through campaigns.
- **Technology:** **Python (Flask + PostgreSQL)**
  - Motivation: Django’s ORM and admin interface speed up campaign management and donation tracking. PostgreSQL ensures ACID consistency for money flows.
- **Communication Pattern:** **Event-driven messaging (RabbitMQ/Kafka)** to notify Tea Management when campaigns succeed.
  - Trade-off: Asynchronous messaging decouples services but makes debugging harder. Fits since campaigns are not real-time critical.

### 3. Sharing Service

- Manages multi-use objects (games, cords, cups, kettles).
- Tracks borrowing/returning and item state.
- Updates the debt book if items are damaged.
- **Communicates with:**
  - **Cab Booking Service** to coordinate shared item usage during bookings.
  - **Check-in Service** for tracking item usage by users entering/exiting.
  - **Lost & Found Service** for reporting lost shared items.
  - **Budgeting Service** to log debts for damaged items.
  - **Notification Service** to alert users/owners about overdue or broken items.
- **Technology:** **Python (FastAPI + PostgreSQL)**
  - Motivation: FastAPI provides lightweight APIs for object state changes. PostgreSQL ensures consistency when tracking loans/returns.
- **Communication Pattern:** **REST API + Event-driven notifications**
  - REST for synchronous lookups (Cab Booking, Check-in).
  - Events for notifying about overdue items or damages.
  - Trade-off: Slightly more complex, but balances responsiveness with decoupling.

### 4. Tea Management Service

- Tracks consumables (tea, sugar, cups, markers).
- Logs usage per user and sends alerts for overuse or low stock.
- **Communicates with:**
  - **Notification Service** for alerts to admins and users.
  - **Fund Raising Service** to receive new consumables funded through campaigns.
  - **Budgeting Service** to update financial records for consumables usage and purchases.
- **Technology:** **Java (Spring Boot + PostgreSQL)**
  - Motivation: Strong relational integrity needed for consumables stock management.
- **Communication Pattern:** **REST API + Event-driven alerts**
  - REST for updates from Fund Raising.
  - Events for pushing low-stock notifications.
  - Trade-off: REST ensures reliability in consumable updates, events provide timely notifications.

### 5. Communication Service

- Provides public and private chat functionality.
- Applies censorship and bans repeat offenders.
- **Communicates with:**
  - **Lost & Found Service** to allow user verification in posts and discussions.
  - **User Management Service** to validate users in chats.
  - **Check-in Service** to verify active users for chat participation.
- **Technology:** **Java (Spring Boot + MongoDB)**
- **Communication Pattern:** **WebSockets + REST**
  - WebSockets for real-time messaging.
  - REST for moderation and bans.
  - Trade-off: WebSockets offer low-latency, but managing state adds complexity.

### 6. Cab Booking Service

- Enables room scheduling (main room, kitchen).
- Prevents conflicts and integrates with Google Calendar.
- **Communicates with:**
  - **Check-in Service** to verify users entering/exiting the Cab.
  - **User Management Service** to validate bookings.
  - **Sharing Service** to coordinate shared item usage during bookings.
  - **Notification Service** to alert users about booking confirmations or conflicts.
- **Technology**: **Python (Flask + Celery + PostgreSQL)** – chosen for flexibility in handling scheduling logic and easy async job management with Celery. PostgreSQL ensures robust relational constraints to avoid double-booking.
- **Communication Pattern**: **REST API** for booking validation; **Events** for sending booking confirmations and updates to related services.
- **Trade-offs**: Python is lightweight and easy to integrate with Google APIs, though concurrency handling requires Celery/RabbitMQ to ensure reliability at scale.

### 7. Check-in Service

- Tracks entry/exit of users and guests (simulated CCTV).
- Notifies admins of unknown visitors.
- **Communicates with:**
  - **Cab Booking Service** to validate user room bookings.
  - **Notification Service** to alert users and admins of events.
  - **Sharing Service** to track item usage by users entering/exiting.
  - **User Management Service** to verify identities.
- **Technology**: **Python (FastAPI + OpenCV)** – chosen for simplicity in integrating AI/ML facial recognition.
- **Communication Pattern**: REST for user check-in/out; events for alerts to Notification.
- **Trade-offs**: Python excels at computer vision but may require optimization for real-time throughput.

### 8. Lost & Found Service

- Users can post announcements about lost/found items.
- Supports comments and resolving posts.
- **Communicates with:**
  - **Communication Service** to verify users participating in posts.
  - **User Management Service** to verify user identities.
  - **Notification Service** for updates on comments or resolved posts.
  - **Sharing Service** for reporting lost shared items.
- **Technology**: **Node.js (Express)** – chosen for lightweight, event-driven handling of posts and user interactions.
- **Communication Pattern**: REST for post management; events for notifications and discussions.
- **Trade-offs**: Node.js is fast for I/O-bound tasks but less suited for CPU-heavy processing (not needed here).

### 9. Budgeting Service

- Tracks finances: incomes, donations, expenses.
- Maintains debt book and generates CSV reports.
- **Communicates with:**
  - **Tea Management Service** to track consumable costs.
  - **Sharing Service** to log debts or damages.
- **Technology**: **Node.js (NestJS)** – chosen for modularity and ability to handle financial transaction APIs.
- **Communication Pattern**: REST for finance queries; events for updating debts/expenses.
- **Trade-offs**: Node.js is excellent for building lightweight APIs, though less strict in typing compared to Java.

### 10. Notification Service

- Sends timely alerts to users, admins, or owners.
- Acts as a **central communication hub** for alerts triggered by other services.
- **Communicates with:**
  - **Lost & Found Service** for post updates.
  - **Check-in Service** for entry/exit notifications.
  - **Cab Booking Service** for booking alerts.
  - **Tea Management Service** for consumable usage alerts.
  - **Budgeting Service** for financial updates.
  - **Sharing Service** for item usage and overdue notifications.
- **Technology**: **Java (Spring Boot)**

---

## Communication Overview

- **REST APIs** are used for synchronous, user-facing operations (e.g., creating bookings, posting lost items).
- **WebSockets** are used for real-time chat in the Communication service.

---

### Architecture Diagram

![Architecture Diagram](https://github.com/user-attachments/assets/6dab3c08-1880-4179-991a-62f030282682)
The diagram shows services as independent modules and arrows indicate communication flows between services.

## Data Management

### Database Architecture

The platform follows a **database-per-service** pattern where each microservice owns its schema and is the only writer/reader of its database. Cross-service data access is handled through APIs (synchronous) or domain events (asynchronous).

### Storage Technologies

| Database       | Services                                                               | Use Cases                                                      |
| -------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------- |
| **PostgreSQL** | User, Lost & Found, Fund Raising, Tea, Sharing, Budgeting, Cab Booking | Structured data, ACID transactions, relational queries         |
| **MongoDB**    | Communication, Check-In, Notification                                  | Unstructured data, real-time messaging, logs, flexible schemas |

### Data Consistency Model

- **Immediate user actions**: Synchronous REST API calls
- **Cross-service propagation**: Asynchronous events with outbox pattern
- **Audit trails**: Asynchronous event processing with idempotent consumers
- **Error handling**: Dead letter queues (DLQ) and retry mechanisms

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
- **Exposes balance information** to other services

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
