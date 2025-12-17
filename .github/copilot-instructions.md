# Copilot Instructions - MedusaJS 2.0 Monorepo

## Project Overview
This is a **MedusaJS 2.0** e-commerce monorepo with a backend (Node.js) and Next.js 15 storefront. It's pre-configured for Railway deployment with PostgreSQL, Redis, MinIO, and MeiliSearch integrations.

**Current Version:** Medusa 2.12.1 | Next.js 15.4.7 | Node 22.x | pnpm 9.10.0

## Architecture & Structure

### Backend (`backend/`)
Built on **MedusaJS 2.0 framework** - a modular e-commerce platform with custom modules, workflows, and subscribers.

**Key Directories:**
- `src/modules/` - Custom Medusa modules (email-notifications, minio-file)
- `src/api/` - File-based REST API routes (`route.ts` files)
- `src/subscribers/` - Event-driven handlers for domain events
- `src/workflows/` - Multi-step business logic flows using `@medusajs/workflows-sdk`
- `src/admin/` - Admin dashboard customizations
- `.medusa/server/` - **Cached build artifacts (delete to clear env cache)**

### Storefront (`storefront/`)
Next.js 15 App Router with TypeScript, using `@medusajs/js-sdk` for backend communication.

**Key Directories:**
- `src/app/[countryCode]/` - Internationalized routes (dynamic region handling)
- `src/modules/` - Feature modules (cart, checkout, products, account)
- `src/lib/` - Shared utilities, data fetching, and search configuration
- `e2e/` - Playwright tests with fixtures pattern

## Critical Workflows

### Initial Setup
```bash
# Backend setup
cd backend
pnpm install
cp .env.template .env  # Configure DATABASE_URL, REDIS_URL, etc.
pnpm ib                # Initialize backend: migrations + seed data
pnpm dev               # Starts backend on :9000 + admin on :9000/app

# Storefront setup
cd storefront
pnpm install
cp .env.local.template .env.local  # Configure NEXT_PUBLIC_MEDUSA_BACKEND_URL
pnpm dev               # Requires backend running on :9000
```

### Important Commands
- **`pnpm ib`** (backend): Custom alias for `init-backend` - runs migrations AND seeds database
- **`pnpm email:dev`** (backend): Opens react-email dev server at :3002 for template previews
- **Clear config cache**: Delete `.medusa/server/` when changing env vars (especially storage/module config)
- **Production build test**: `pnpm build && pnpm start` (backend) - reproduces cloud environment

### Package Manager
**Use `pnpm` exclusively** - lockfiles are pnpm-specific. Scripts use `medusajs-launch-utils` wrappers (`init-backend`, `launch-storefront`, `await-backend`) for coordinated startup.

## Project-Specific Patterns

### Backend: Custom Modules
Located in `src/modules/`, these extend Medusa functionality:

**MinIO File Module** ([README](backend/src/modules/minio-file/README.md))
- Replaces local file storage with S3-compatible MinIO
- Auto-creates `medusa-media` bucket with public-read policy
- Uses ULID for unique filenames
- Fallback to local storage if env vars missing
- **Config cached**: Must delete `.medusa/server/` after changing bucket name

**Email Notifications** ([README](backend/src/modules/email-notifications/README.md))
- Uses `react-email` for templates (base template in `templates/base.tsx`)
- Supports Resend or SendGrid providers
- Example: `src/subscribers/invite-created.ts` - triggers email on user invite
```typescript
await notificationModuleService.createNotifications({
  to: email,
  channel: 'email',
  template: EmailTemplates.INVITE_USER,
  data: { emailOptions: { subject, replyTo }, inviteLink, preview }
})
```

### Backend: Subscribers Pattern
Event-driven handlers in `src/subscribers/` - see [invite-created.ts](backend/src/subscribers/invite-created.ts):
```typescript
export default async function handler({ event: { data }, container }: SubscriberArgs) {
  const service = container.resolve(Modules.NOTIFICATION)
  // Handle event data.id
}
export const config: SubscriberConfig = { event: "user.invite.created" }
```
**Must export:** async function + `config` object with `event` property

### Backend: API Routes
File-based routing: `src/api/[admin|store]/<path>/route.ts` ([README](backend/src/api/README.md))
- Export HTTP method functions: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`
- Example: `src/api/store/hello-world/route.ts` → `/store/hello-world`
```typescript
export async function GET(req: MedusaRequest, res: MedusaResponse) {
  const service = req.scope.resolve("productModuleService")
  res.json({ data })
}
```

### Backend: Workflows
Multi-step business logic using `@medusajs/workflows-sdk` ([README](backend/src/workflows/README.md)):
```typescript
const step1 = createStep("step-1", async (input, { container }) => {
  const service = container.resolve(Modules.PRODUCT)
  return new StepResponse(result, compensationData)
})

const myWorkflow = createWorkflow<Input, Output>("workflow-name", (input) => {
  const result = step1(input)
  return { result }
})
```

### Storefront: Region Handling
Next.js middleware manages country/region routing ([middleware.ts](storefront/src/middleware.ts)):
- Routes start with `/[countryCode]` (e.g., `/us`, `/eu`)
- Region map cached in memory (1hr), fetched from backend `/store/regions`
- Default region: `NEXT_PUBLIC_DEFAULT_REGION` (defaults to "us")

### Storefront: Data Fetching
Uses `@medusajs/js-sdk` (not REST client) - SDK resolves modules automatically:
```typescript
import { HttpTypes } from "@medusajs/types"
import { sdk } from "@/lib/config"

const { products } = await sdk.store.product.list({ region_id })
```

### Environment Configuration
**Backend** (`backend/.env`):
- `DATABASE_URL` - PostgreSQL connection
- `REDIS_URL` - Optional (falls back to simulated redis)
- `MINIO_*` - Optional MinIO config (falls back to local storage)
- `RESEND_API_KEY` or `SENDGRID_API_KEY` - Email provider
- `STRIPE_API_KEY` - Payment provider
- `MEILISEARCH_*` - Search provider
- **Critical**: Delete `.medusa/server/` after changing module-related vars

**Storefront** (`storefront/.env.local`):
- `NEXT_PUBLIC_MEDUSA_BACKEND_URL` - Backend URL (default: http://localhost:9000)
- `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` - **Required** (obtained from admin dashboard)
- `NEXT_PUBLIC_DEFAULT_REGION` - Default country code

## External Dependencies
- **PostgreSQL** - Required, no fallback
- **Redis** - Optional (simulated fallback)
- **MinIO** - Optional (local file fallback)
- **MeiliSearch** - Search provider (@rokmohar/medusa-plugin-meilisearch)
- **Stripe** - Payment provider (@medusajs/payment-stripe)
- **Resend/SendGrid** - Email providers (one required for notifications)

## Testing
- **E2E**: Playwright tests in `storefront/e2e/`
- Fixture pattern: `e2e/fixtures/` for page objects
- Run: `pnpm test-e2e` (in storefront)
- Setup scripts: `e2e/tests/global/setup.ts` for auth state

## Common Pitfalls
1. **Cached config**: Always delete `.medusa/server/` when changing module config (MinIO bucket, providers)
2. **Module resolution**: Use `container.resolve(Modules.X)` not direct imports in subscribers/workflows
3. **Publishable key missing**: Storefront will fail startup without `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`
4. **Seed before dev**: First-time setup MUST run `pnpm ib` to initialize database schema
5. **Monorepo context**: Backend must be running for storefront dev/build (uses `await-backend` helper)
