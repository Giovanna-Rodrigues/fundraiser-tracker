# Implementation Plan — Fundraiser Tracker

**Date:** 2026-03-07
**Status:** In progress

---

## Codebase Analysis Summary

### What is already implemented

| Module | Status | Notes |
|---|---|---|
| Order management | Complete | pending → preparing → ready → delivered flow |
| Campaign management | Complete | Single active campaign enforcement |
| Product management | Complete | Combo products supported |
| Pathfinder management | Complete | CRUD with documents stored as JSONB |
| Financial module (UI) | Created, unverified | FinancialTracking.vue exists but is untracked in git |
| Document tracking (UI) | Created, unverified | DocumentTracking.vue exists but is untracked in git |
| Financial DB tables | Migration written, unverified | FINANCIAL-DOCUMENT-TRACKING-MIGRATION.sql untracked — likely not applied to Supabase yet |
| User management | Complete | Was admin-only, to be unrestricted |
| Dashboard | Partial | Missing payment/pickup breakdowns |
| Kitchen | Skeleton only | Minimal implementation, no filtering logic |

### Critical issues found

1. **AppSidebar.vue is broken** (`src/layout/AppSidebar.vue` lines 25–31): garbled text on lines 29–30 causes syntax errors. Line 25 has `return true` before the role check, making the filter a no-op — all items show regardless of role.
2. **Role restrictions exist in 3 places**: `src/router/index.ts` blocks `/financial`, `/documents`, `/users` by role. `src/config/navigation.ts` hides those menu items. Sidebar filter (broken) was meant to enforce the same.
3. **Financial DB migration likely not applied**: migration file and view files are all untracked — created in a previous session but probably not run in Supabase.
4. **Orders have no "not picked up" status** and **PaymentMethod is required** (no "pay later" option).

---

## Phase 1 — Remove all access restrictions

**Files:** `src/router/index.ts`, `src/config/navigation.ts`, `src/layout/AppSidebar.vue`

- [x] **Router**: Remove `meta: { requiresRole }` from `/financial`, `/documents`, `/users`. Keep `beforeEach` only for unauthenticated redirect to `/login`.
- [x] **Navigation config**: Remove all `requiredRoles` properties from every menu item.
- [x] **Sidebar**: Fix corrupted lines (29–30). Simplify filter so every item always shows. Delete role check logic entirely.

> Note: UserManagement will also be unrestricted per user instruction. Anyone logged in can invite users and manage roles.

---

## Phase 2 — Verify and activate the financial module

- [ ] Open Supabase SQL Editor and check whether `FeeTypesTable`, `PathfinderFeesTable`, `PaymentsTable` exist.
- [ ] If not, run `db/FINANCIAL-DOCUMENT-TRACKING-MIGRATION.sql`.
- [ ] Confirm `pathfinder_financial_summary` view is present.
- [ ] Review `FinancialTracking.vue` and `DocumentTracking.vue` end-to-end against store actions and fix any connection issues.

> No new tables needed — schema and UI were written in previous session, just need to be activated and validated.

---

## Phase 3 — Order system: "not picked up" and "pay later"

### Database changes

Two safe `ALTER TABLE` changes to `OrdersTable` (additive, no data loss):

```sql
-- 1. Add 'not_picked_up' to the Status constraint
ALTER TABLE "OrdersTable" DROP CONSTRAINT IF EXISTS orderstable_status_check;
ALTER TABLE "OrdersTable" ADD CONSTRAINT orderstable_status_check
  CHECK ("Status" IN ('pending', 'preparing', 'ready', 'delivered', 'not_picked_up'));

-- 2. Allow PaymentMethod to be NULL (pay later)
ALTER TABLE "OrdersTable" ALTER COLUMN "PaymentMethod" DROP NOT NULL;
ALTER TABLE "OrdersTable" DROP CONSTRAINT IF EXISTS orderstable_paymentmethod_check;
ALTER TABLE "OrdersTable" ADD CONSTRAINT orderstable_paymentmethod_check
  CHECK ("PaymentMethod" IS NULL OR "PaymentMethod" IN ('card', 'cash', 'pix-church', 'pix-qr'));
```

### TypeScript interface updates (`src/stores/fundraiser.ts`)

- `Status`: add `'not_picked_up'`
- `PaymentMethod`: make optional (`PaymentMethod?: 'card' | 'cash' | 'pix-church' | 'pix-qr'`)

### Frontend changes

**OrderEntry.vue:**
- [ ] Add "Pagar depois" toggle — when selected, PaymentMethod field hidden and submitted as `null`
- [ ] Add "Pedido não retirado" toggle — when selected, Status set to `not_picked_up` instead of `pending`

**Kitchen.vue:**
- [ ] Implement proper order queue display (currently skeleton)
- [ ] Filter: only show `Status IN ('pending', 'preparing', 'ready')` — exclude `not_picked_up` and `delivered`
- [ ] Status transition buttons per order card: pending → preparing → ready → delivered

**Dashboard.vue:**
- [ ] Replace/augment order summary with 3 distinct categories:
  1. **Pago e retirado**: `PaymentMethod IS NOT NULL AND Status = 'delivered'`
  2. **Pago, não retirado**: `PaymentMethod IS NOT NULL AND Status = 'not_picked_up'`
  3. **Não pago**: `PaymentMethod IS NULL`
- [ ] Allow marking an existing order as "not picked up" from dashboard order list

---

## Phase 4 — Centralized Pathfinder management

Data is already centralized at DB level — every module references `PathfindersTable` via `PathfinderId`. The store loads all pathfinders once and all views read from that store. No structural DB change needed.

**Enhance PathfinderManagement.vue with expandable detail panels per pathfinder:**

- [ ] **Cadastro** (already exists): name, type, contact, address, parent info, registration year, active status
- [ ] **Documentos**: document completion status scoped to this pathfinder — mark documents received/missing directly
- [ ] **Financeiro**: total owed, paid, overdue fees, assigned fees — add payment directly
- [ ] **Pedidos**: order history for this pathfinder with amounts and status

> This does NOT replace FinancialTracking.vue or DocumentTracking.vue — those remain as bulk/overview pages. PathfinderManagement becomes the per-person detail hub.

- [ ] Verify OrderEntry.vue uses pathfinder dropdown from store (not free-text) and always sets `PathfinderId`

---

## Phase 5 — Complete the Kitchen view

- [ ] Display live order queue grouped by status: Pending | Preparing | Ready
- [ ] Exclude `not_picked_up` and `delivered` orders
- [ ] Status change buttons per order card
- [ ] Realtime or periodic refresh

---

## Execution Order

| Step | What | Risk |
|---|---|---|
| 1 | Remove all role restrictions (router + navigation + sidebar fix) | Low — pure frontend |
| 2 | Verify financial module DB — run migration if needed | Medium — DB op, reversible |
| 3 | Validate FinancialTracking.vue + DocumentTracking.vue end-to-end | Low |
| 4 | DB: ALTER OrdersTable for new status + nullable payment | Low — additive only |
| 5 | Update Order interface + store actions | Low |
| 6 | Update OrderEntry.vue (pay later + not picked up) | Low |
| 7 | Implement Kitchen.vue | Low |
| 8 | Update Dashboard.vue with three order categories | Low |
| 9 | Enhance PathfinderManagement.vue with tabs | Medium — larger view change |

---

## What does NOT change

- Database structure for pathfinders, campaigns, products — solid
- Store's loading/state logic — already well-structured
- Authentication flow — keep it (removing role-based page restrictions only, not auth itself)
- Financial DB triggers — handle amounts and status automatically
