# QVITAL Backend - AI Context & Development Guide

## Project Overview

QVITAL is a wellness and marketplace SaaS platform focused on:

* healthy habits
* nutrition
* wellness
* emotional wellbeing
* recipes
* product marketplace
* AI-assisted wellness tools

Backend stack:

* Ruby on Rails 8.0 API only
* PostgreSQL (Supabase)
* JWT authentication with Supabase (ES256 / JWKS)
* Supabase Storage
* RESTful APIs
* Wompi payments (Colombia)
* Future MercadoPago integration

Deployment target:

* Render

Database:

* Supabase PostgreSQL

---

# Core Backend Principles

## Architecture Philosophy

The backend must remain:

* modular
* scalable
* maintainable
* API-first
* multi-tenant ready in the future

Avoid monolithic business logic.

Controllers should stay thin.

Business logic belongs in:

* interactors (`app/interactors/`)
* services (`app/services/`)
* POROs
* query objects

---

# Rails Stack

Main technologies:

* Rails 8.0 API only
* PostgreSQL / ActiveRecord
* JWT + Supabase Auth (JWKS)
* `blueprinter` — JSON serialization (blueprints in `app/blueprints/`)
* `rack-cors` — CORS middleware
* `solid_cache` — DB-backed cache (no Redis needed yet)
* `solid_queue` — DB-backed job queue (no Sidekiq/Redis needed yet)
* `solid_cable` — DB-backed Action Cable
* `kamal` — deployment tool
* `dotenv-rails` — environment variables (dev/test)

---

# Authentication Architecture

Authentication is handled by Supabase Auth.

Flow:

1. User authenticates via Supabase.
2. Frontend receives JWT access token.
3. Frontend sends token as `Authorization: Bearer <jwt>`.
4. `Authenticatable` concern validates token against Supabase JWKS.
5. `Auth::SyncUser` creates/updates the local User record.
6. `current_user` is available in all authenticated controllers.

IMPORTANT:

* Use ES256 only.
* Use JWKS validation.
* Never use legacy HS256 secret.
* Never store Supabase private keys.

---

# Authentication Rules

Endpoints:

```
POST /api/v1/auth/sync             # Validates JWT, syncs user, returns UserBlueprint
POST /api/v1/auth/update_metadata  # Forces Supabase metadata sync (debug)
```

Backend responsibilities:

* validate JWT
* synchronize user (find_or_create by supabase_uid)
* assign default role: `cliente`
* assign default level: `Cliente`
* call `Auth::UpdateSupabaseMetadata` on new user or role change

User table columns:

* `supabase_uid` (unique)
* `hlf_id` (unique, optional — distributor network ID)
* `email` (unique)
* `role` (admin | cliente)
* `level_id` (FK → levels)
* `name`, `phone`
* `address` (jsonb)

---

# API Architecture

## Route Map

```
Base: /api/v1/

# Auth (public)
POST   /auth/sync
POST   /auth/update_metadata

# Catalog (requires auth)
GET    /products
GET    /categories

# Marketplace — Cart (requires auth)
GET    /marketplace/cart
POST   /marketplace/cart/clear
POST   /marketplace/cart/items
PATCH  /marketplace/cart/items/:id
DELETE /marketplace/cart/items/:id

# Marketplace — Orders (requires auth)
GET    /marketplace/orders
POST   /marketplace/orders/prepare
POST   /marketplace/orders/complete

# Marketplace — Checkout (requires auth, except webhook)
POST   /marketplace/checkout/prepare
POST   /marketplace/checkout/webhook   # no auth — Wompi webhook
GET    /marketplace/checkout/status

# Admin — Products (requires admin role)
GET    /admin/products
GET    /admin/products/:id
POST   /admin/products
PATCH  /admin/products/:id
DELETE /admin/products/:id

# Admin — Orders (requires admin role)
GET    /admin/orders
GET    /admin/orders/:id
PATCH  /admin/orders/:id

# Health
GET    /up
```

## Shared Contract — Frontend Sync

**Every time you create or modify an API endpoint, you MUST also:**

1. Update or create the corresponding endpoint doc in the frontend repo:
   ```
   /mnt/d/QVITAL/qvital-frontend/docs/endpoints/
   ```
   One markdown file per resource (e.g. `orders.md`, `checkout.md`). Include: method, path, auth required, request params, response shape, and error codes.

2. Update the schema snapshot:
   ```
   /mnt/d/QVITAL/qvital-frontend/docs/schema.rb
   ```
   Copy the current `db/schema.rb` contents verbatim so the frontend always has a reference of the live DB structure.

This is a hard rule — a backend change without the corresponding frontend doc update is an incomplete task.

## Rules

All endpoints must:

* return JSON
* use proper HTTP status codes
* handle errors gracefully
* avoid leaking internal exceptions

Use:

* 200 OK
* 201 Created
* 401 Unauthorized
* 403 Forbidden
* 404 Not Found
* 422 Unprocessable Entity

Avoid:

* generic 500 responses without handling

---

# Controllers

Controllers must:

* orchestrate requests
* validate params (strong params)
* call interactors/services
* serialize responses with blueprints

Controllers must NOT:

* contain business logic
* contain complex queries
* contain payment logic

Admin controllers include an explicit `authorize_admin!` check before every action.

---

# Business Logic — Interactor Pattern

Business logic belongs in `app/interactors/`.
External integrations belong in `app/services/`.

**Interactor convention:**

* Each interactor exposes a `.call(args)` class method.
* Returns a result struct with `success?`, data attributes, and `error` / `errors`.
* Wrap multi-step DB operations in `ActiveRecord::Base.transaction`.

**Existing interactor namespaces:**

```
Auth::
  SyncUser
  UpdateSupabaseMetadata

Products::
  ListForUser

Categories::
  List

Marketplace::Carts::
  FetchOpen
  AddItem
  UpdateItem
  RemoveItem
  Clear

Marketplace::Orders::
  List
  Prepare
  Complete

Marketplace::Checkout::
  Prepare
  Webhook
  Status

Admin::Products::
  List / Show / Create / Update / Destroy

Admin::Orders::
  List / Show / Update
```

---

# Database Schema

## Tables

| Table             | Purpose                                      |
|-------------------|----------------------------------------------|
| users             | Authenticated users (Supabase-synced)        |
| levels            | Pricing tiers (Cliente, Distribuidor, etc.)  |
| categories        | Product categories with display order        |
| products          | Catalog items (name, SKU, PV, image_url)     |
| product_prices    | Price per product × level combination        |
| carts             | Active shopping carts (open/completed/abandoned) |
| cart_items        | Items in a cart (quantity + price_snapshot)  |
| purchase_intents  | Checkout session anchor (external_reference) |
| purchases         | Confirmed purchase with shipping info        |
| purchase_items    | Line items with unit/tax/total breakdown     |
| orders            | Fulfillment record (status, tracking)        |
| order_items       | Items in an order                            |
| payments          | Payment record linked to Wompi transaction   |
| health_checks     | Rails health check ping table                |

## Timezones

IMPORTANT:

* Database stores UTC only.
* Rails uses `Time.current` (timezone-aware).
* Frontend converts to local timezone.

Avoid `Time.now`.

---

# Cart & Order Workflow

Full lifecycle:

1. **Cart** — user adds/updates/removes `CartItem` records on an open `Cart`.
2. **Prepare order** — `Marketplace::Orders::Prepare` creates:
   - `PurchaseIntent` (holds `external_reference`, anchors the checkout session)
   - `Purchase` (shipping address, recipient info, totals)
   - `PurchaseItem` records (unit_price, line_subtotal, line_tax, line_total)
   - `Order` + `OrderItem` records (fulfillment view)
3. **Prepare checkout** — `Marketplace::Checkout::Prepare` calls `Wompi::CheckoutPrepare`, creates/updates `Payment` with `checkout_url`.
4. **User pays** — redirected to Wompi hosted checkout.
5. **Webhook** — Wompi calls `POST /marketplace/checkout/webhook`; `Marketplace::Checkout::Webhook` validates signature, updates `Payment` status, auto-calls `Complete` if approved.
6. **Complete order** — `Marketplace::Orders::Complete` confirms `Purchase` and `Order` status to `confirmed`; marks `Cart` as `completed`.

---

# Product System

Product rules:

* A product may have multiple `ProductPrice` records (one per level).
* `image_url` / `image_path` store Supabase Storage references.
* `pv` — point value for distributor network.
* `sku` — unique stock-keeping unit (optional).
* `active` flag controls visibility in catalog.

Serialized with `ProductBlueprint`:
* Default view: id, name, description, image_url, pv, sku, price (per user level), currency, category.
* Admin view adds: active, created_at, updated_at.

---

# User Levels

Supported levels:

* Cliente
* Cliente VIP
* Distribuidor
* Distribuidor VIP
* Constructor del Éxito
* Mayorista

Product pricing varies by level via `product_prices` table.

---

# Serializers (Blueprints)

The project uses the `blueprinter` gem. Blueprints live in `app/blueprints/`.

Existing blueprints:

* `UserBlueprint`
* `ProductBlueprint` (views: default, :admin)
* `CategoryBlueprint`
* `LevelBlueprint`
* `CartBlueprint` / `CartItemBlueprint`
* `OrderBlueprint` / `OrderItemBlueprint`
* `PurchaseBlueprint` / `PurchaseItemBlueprint`
* `PurchaseIntentBlueprint`
* `PaymentBlueprint`

Responses should be:

* predictable and minimal
* frontend-friendly
* no deeply nested payloads or unnecessary attributes

---

# External Services (Wompi)

Wompi integration lives in `app/services/wompi/`.

| Class                    | Responsibility                                    |
|--------------------------|---------------------------------------------------|
| `Wompi::Config`          | ENV-backed config (keys, URLs, secrets)           |
| `Wompi::CheckoutPrepare` | Generates checkout fields + integrity signature   |
| `Wompi::Client`          | Fetches transaction status from Wompi REST API    |
| `Wompi::Signature`       | HMAC signature generation and webhook validation  |

Currency: **COP** (Colombian Peso). Amounts sent to Wompi are in centavos (× 100).

---

# Payment Architecture

Current provider: **Wompi**

Future: MercadoPago

Payment flow:

1. PurchaseIntent created (anchors `external_reference`)
2. `Marketplace::Checkout::Prepare` calls Wompi, creates Payment record
3. User redirected to Wompi hosted checkout
4. Wompi webhook fires `transaction.updated` event
5. `Marketplace::Checkout::Webhook` validates signature, maps status
6. Payment status updated (approved / rejected / pending)
7. If approved → `Marketplace::Orders::Complete` auto-called

---

# Payment Rules

Never trust frontend payment confirmation.

Webhooks are the source of truth.

Always store:

* `provider_payment_id`
* `external_reference`
* `provider_preference_id`
* provider status string
* `raw_payload` (jsonb — full webhook body)
* `currency`

Payment statuses (enum):

* pending (0)
* approved (1)
* rejected (2)

Future: cancelled, refunded.

---

# Webhooks

Webhook processing must:

* validate Wompi signature (`Wompi::Signature`)
* validate `environment` field matches expected env
* be idempotent — find_or_create Payment by `external_reference`
* avoid duplicate processing
* log failures safely

---

# Admin Features

Admin-only routes under `/api/v1/admin/` (require `role == "admin"`):

**Products:**
* Full CRUD with bulk pricing per level.
* Filters: category_id, search (name/SKU), active status.

**Orders:**
* List all orders with filters: status, search (purchase_number / customer name), date range.
* Show order with full customer, purchase, payment, and item details.
* Update: status, shipping_date_estimated, shipping_date_real, tracking_info (jsonb).
* Pagination: page / per_page (max 50).

---

# Environment Variables

Required environment variables:

```
# Supabase
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY

# Wompi
WOMPI_ENV                   # sandbox | production
WOMPI_PUBLIC_KEY
WOMPI_PRIVATE_KEY
WOMPI_INTEGRITY_SECRET
WOMPI_EVENTS_SECRET
WOMPI_CHECKOUT_URL
WOMPI_API_BASE_URL
WOMPI_REDIRECT_URL

# Dev/Staging helpers
MARKETPLACE_MOCK_AUTO_APPROVE  # "true" to skip real payment check

# Transactional email (OrderMailer — order confirmation)
RESEND_API_KEY                 # Resend API key. Without it, ActionMailer falls back to :test (no real email sent)
ADMIN_NOTIFICATION_EMAIL       # bcc'd on every order confirmation email
MAILER_FROM_EMAIL              # optional, defaults to pedidos@qvital.com — must be a domain verified in Resend
```

**Note:** these three must be set wherever the app actually runs in production (Render dashboard — see "Deployment target" above), not just in the local `.env`. `dotenv-rails` is a `development, test` only gem (see Gemfile), so `.env` is never read when `RAILS_ENV=production`.

---

# Supabase Storage

Storage bucket: `products`

Rules:

* public read
* admin-only upload

Frontend uploads directly to Supabase Storage.

Rails stores only `image_url` and `image_path`.

---

# Query Performance

Avoid:

* N+1 queries — use `.includes()` for associations
* oversized JSON responses

Prefer:

* eager loading via `includes`
* blueprints for serialization
* pagination (`page`, `per_page`)

---

# Security Rules

Always:

* validate JWT via JWKS
* check `authorize_admin!` on admin endpoints
* validate resource ownership (purchases, cart items belong to current_user)
* sanitize params with strong params
* validate Wompi webhook signature before processing

Never:

* trust frontend roles
* trust frontend prices (always recalculate from DB)
* trust payment status from frontend (webhooks only)

---

# Error Handling

Prefer:

* explicit error handling in interactors
* meaningful error messages returned in `error` / `errors` fields
* service-level rescue handling

Avoid:

* swallowing exceptions silently

Controllers pattern:

```ruby
result = SomeInteractor.call(...)
if result.success?
  render json: SomeBlueprint.render(result.data), status: :ok
else
  render json: { error: result.error }, status: :unprocessable_entity
end
```

---

# Background Jobs

`solid_queue` is already installed (DB-backed, no Redis/Sidekiq needed).

Planned async tasks:

* payment reconciliation
* email sending
* AI processing
* analytics
* notifications

To add a job: inherit from `ApplicationJob`, enqueue with `MyJob.perform_later(...)`.

---

# AI Features (Future)

Planned future modules:

* AI wellness assistant
* BMI calculator
* body fat estimation
* nutrition recommendations
* emotional wellness assistant
* habit tracking

Backend should remain extensible for AI services.

---

# Code Style

Prefer:

* readable code with explicit naming
* modular interactors/services
* POROs
* model scopes for reusable queries

Avoid:

* fat models
* giant service classes
* callback-heavy logic (only `after_update :sync_role_to_supabase` on User is justified)

---

# Git Workflow

Branches:

* `main` → production
* `develop` → active development

Feature branches: `feature/<feature-name>`

---

# AI Assistant Expectations

When generating backend code:

* **After any endpoint change or creation: update `/mnt/d/QVITAL/qvital-frontend/docs/endpoints/<resource>.md` and copy `db/schema.rb` to `/mnt/d/QVITAL/qvital-frontend/docs/schema.rb`.** This is non-negotiable.
* Follow existing architecture — thin controllers, interactors for logic.
* Use `blueprinter` blueprints for serialization (not jbuilder or as_json).
* Use the Result pattern in interactors (success?, error, data attributes).
* Use `solid_queue` for background jobs (not Sidekiq).
* Currency is COP; amounts to Wompi are in centavos.
* Wrap multi-step DB writes in `ActiveRecord::Base.transaction`.
* Always eager-load associations to avoid N+1.
* Admin actions must call `authorize_admin!` before proceeding.
* Prioritize maintainability over cleverness.
* Avoid unnecessary gems.

Do not:

* introduce massive abstractions
* generate magic-heavy code
* tightly couple modules
* add `approved_at` or `cancelled` / `refunded` statuses — Payment enum only has pending/approved/rejected for now

---

# Scalability Vision

QVITAL is intended to evolve into:

* a wellness SaaS ecosystem
* marketplace platform
* distributor network platform (hlf_id already on users)

Architecture decisions should preserve future scalability.

Future possibilities:

* subscriptions
* referral systems
* multi-country payments (MercadoPago)
* multi-tenant support
* analytics dashboards
* mobile applications
