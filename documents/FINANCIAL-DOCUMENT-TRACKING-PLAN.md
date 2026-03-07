# Implementation Plan: Financial Tracking & Document Management

## Context

The fundraiser tracker currently manages sales campaigns for the Pathfinder Club but lacks comprehensive member management capabilities. The club needs to track:

**Financial Management (Treasurer):**
- Multiple fee types: annual membership, monthly dues, event fees (DSA Campuri with April deadline), equipment purchases
- Installment/split payment tracking with full payment history
- Payment sources: card, cash, pix-church, pix-qr, 7me, church (matching fundraiser payment methods)
- Who has paid, who hasn't, amounts owed/remaining, payment deadlines
- Follow-up visibility for contacting parents about outstanding balances

**Document Management (Secretary):**
- Track registration updates for current year
- Monitor required documents per pathfinder category (Desbravador, Staff, Directors)
- Document requirements vary by type:
  - Everyone: ID + CPF, SUS card, Proof of residence
  - Desbravador only: Parent/guardian ID + CPF, Vaccination card
  - Staff/Directors only: Criminal background check
  - Optional: Health insurance card
- Checkbox tracking only (no file uploads) for document receipt status

**Access Control:**
- Extend role system beyond current admin/user to include treasurer and secretary roles
- Separate screens for each role's responsibilities
- Role-based navigation menu filtering

---

## Database Schema Changes

### 1. Extend PathfindersTable

**File:** `db/FINANCIAL-DOCUMENT-TRACKING-MIGRATION.sql`

Add columns for pathfinder categorization and document tracking:

```sql
ALTER TABLE "PathfindersTable"
ADD COLUMN "Type" TEXT DEFAULT 'desbravador' CHECK ("Type" IN ('desbravador', 'staff', 'directors')),
ADD COLUMN "Email" TEXT,
ADD COLUMN "Phone" TEXT,
ADD COLUMN "ParentName" TEXT,
ADD COLUMN "ParentEmail" TEXT,
ADD COLUMN "ParentPhone" TEXT,
ADD COLUMN "BirthDate" DATE,
ADD COLUMN "Address" TEXT,
ADD COLUMN "Notes" TEXT,
ADD COLUMN "IsActive" BOOLEAN DEFAULT true,
ADD COLUMN "RegistrationYear" INTEGER,
ADD COLUMN "Documents" JSONB DEFAULT '{}'::jsonb,
ADD COLUMN "UpdatedAt" TIMESTAMPTZ DEFAULT NOW();

-- Indexes for filtering
CREATE INDEX idx_pathfinders_type ON "PathfindersTable"("Type");
CREATE INDEX idx_pathfinders_active ON "PathfindersTable"("IsActive");
CREATE INDEX idx_pathfinders_registration_year ON "PathfindersTable"("RegistrationYear");
```

**Documents JSONB structure:**
```json
{
  "id_cpf": { "status": "received", "updatedAt": "2026-02-06", "updatedBy": "user-id", "notes": "..." },
  "sus_card": { "status": "missing", ... },
  "proof_residence": { "status": "received", ... },
  "parent_id_cpf": { "status": "received", ... },
  "vaccination_card": { "status": "received", ... },
  "criminal_background": { "status": "received", "expiryDate": "2027-02-06", ... },
  "health_insurance": { "status": "received", ... }
}
```

### 2. Create FeeTypesTable

Defines fee types that can be assigned to pathfinders:

```sql
CREATE TABLE "FeeTypesTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "Description" TEXT,
  "Amount" NUMERIC(10,2) NOT NULL,
  "FeeCategory" TEXT NOT NULL CHECK ("FeeCategory" IN ('membership', 'monthly', 'event', 'equipment', 'other')),
  "RecurrenceType" TEXT CHECK ("RecurrenceType" IN ('one-time', 'monthly', 'annual')),
  "AppliesTo" TEXT[] DEFAULT ARRAY['desbravador', 'staff', 'directors'],
  "DueDate" DATE,
  "IsActive" BOOLEAN DEFAULT true,
  "Year" INTEGER,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. Create PathfinderFeesTable

Links fee types to specific pathfinders with payment tracking:

```sql
CREATE TABLE "PathfinderFeesTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "PathfinderId" TEXT NOT NULL REFERENCES "PathfindersTable"("PK") ON DELETE CASCADE,
  "FeeTypeId" TEXT NOT NULL REFERENCES "FeeTypesTable"("PK") ON DELETE CASCADE,
  "Amount" NUMERIC(10,2) NOT NULL,
  "DueDate" DATE NOT NULL,
  "Status" TEXT DEFAULT 'pending' CHECK ("Status" IN ('pending', 'partial', 'paid', 'overdue', 'waived')),
  "AmountPaid" NUMERIC(10,2) DEFAULT 0,
  "AmountRemaining" NUMERIC(10,2) NOT NULL,
  "Notes" TEXT,
  "AssignedAt" TIMESTAMPTZ DEFAULT NOW(),
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE ("PathfinderId", "FeeTypeId")
);
```

**Critical trigger:** Auto-update status and remaining amount when payments change:

```sql
CREATE OR REPLACE FUNCTION update_pathfinder_fee_status()
RETURNS TRIGGER AS $$
BEGIN
  NEW."AmountRemaining" := NEW."Amount" - COALESCE(NEW."AmountPaid", 0);

  IF NEW."AmountPaid" >= NEW."Amount" THEN
    NEW."Status" := 'paid';
  ELSIF NEW."AmountPaid" > 0 THEN
    NEW."Status" := 'partial';
  ELSIF NEW."DueDate" < CURRENT_DATE AND NEW."Status" IN ('pending', 'partial') THEN
    NEW."Status" := 'overdue';
  END IF;

  NEW."UpdatedAt" := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 4. Create PaymentsTable

Tracks all payments made toward fees:

```sql
CREATE TABLE "PaymentsTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "PathfinderId" TEXT NOT NULL REFERENCES "PathfindersTable"("PK") ON DELETE CASCADE,
  "PathfinderFeeId" TEXT NOT NULL REFERENCES "PathfinderFeesTable"("PK") ON DELETE CASCADE,
  "Amount" NUMERIC(10,2) NOT NULL CHECK ("Amount" > 0),
  "PaymentMethod" TEXT NOT NULL CHECK ("PaymentMethod" IN ('card', 'cash', 'pix-church', 'pix-qr', '7me', 'church')),
  "PaymentDate" DATE NOT NULL DEFAULT CURRENT_DATE,
  "ReceivedBy" UUID REFERENCES auth.users(id),
  "Notes" TEXT,
  "ReceiptNumber" TEXT,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);
```

**Critical trigger:** Update PathfinderFee when payment is added/deleted:

```sql
CREATE OR REPLACE FUNCTION update_pathfinder_fee_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE "PathfinderFeesTable"
  SET "AmountPaid" = "AmountPaid" + NEW."Amount"
  WHERE "PK" = NEW."PathfinderFeeId";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION revert_pathfinder_fee_on_payment_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE "PathfinderFeesTable"
  SET "AmountPaid" = "AmountPaid" - OLD."Amount"
  WHERE "PK" = OLD."PathfinderFeeId";
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
```

All tables follow the existing PK/SK pattern (FEETYPE#uuid, PATHFINDERFEE#uuid, PAYMENT#uuid) with auto-generation triggers and RLS policies for authenticated users.

---

## TypeScript Interfaces

**File:** `src/stores/fundraiser.ts`

### Extend Pathfinder Interface

```typescript
export interface Pathfinder {
  PK: string
  SK: string
  Name: string
  Type: 'desbravador' | 'staff' | 'directors'
  Email?: string
  Phone?: string
  ParentName?: string
  ParentEmail?: string
  ParentPhone?: string
  BirthDate?: string
  Address?: string
  Notes?: string
  IsActive: boolean
  RegistrationYear?: number
  Documents: DocumentStatusMap
  CreatedAt: string
  UpdatedAt: string
}
```

### New Interfaces

```typescript
export interface DocumentStatus {
  status: 'received' | 'missing'
  updatedAt?: string
  updatedBy?: string
  expiryDate?: string  // For criminal background checks
  notes?: string
}

export interface DocumentStatusMap {
  id_cpf?: DocumentStatus
  sus_card?: DocumentStatus
  proof_residence?: DocumentStatus
  parent_id_cpf?: DocumentStatus
  vaccination_card?: DocumentStatus
  criminal_background?: DocumentStatus
  health_insurance?: DocumentStatus
}

export interface FeeType {
  PK: string
  SK: string
  Name: string
  Description?: string
  Amount: number
  FeeCategory: 'membership' | 'monthly' | 'event' | 'equipment' | 'other'
  RecurrenceType?: 'one-time' | 'monthly' | 'annual'
  AppliesTo: ('desbravador' | 'staff' | 'directors')[]
  DueDate?: string
  IsActive: boolean
  Year?: number
  CreatedAt: string
  UpdatedAt: string
}

export interface PathfinderFee {
  PK: string
  SK: string
  PathfinderId: string
  FeeTypeId: string
  Amount: number
  DueDate: string
  Status: 'pending' | 'partial' | 'paid' | 'overdue' | 'waived'
  AmountPaid: number
  AmountRemaining: number
  Notes?: string
  AssignedAt: string
  CreatedAt: string
  UpdatedAt: string
}

export interface Payment {
  PK: string
  SK: string
  PathfinderId: string
  PathfinderFeeId: string
  Amount: number
  PaymentMethod: 'card' | 'cash' | 'pix-church' | 'pix-qr' | '7me' | 'church'
  PaymentDate: string
  ReceivedBy?: string
  Notes?: string
  ReceiptNumber?: string
  CreatedAt: string
}

export interface PathfinderFinancialSummary {
  pathfinder: Pathfinder
  totalFeesAssigned: number
  totalAmountOwed: number
  totalAmountPaid: number
  totalAmountRemaining: number
  overdueFeesCount: number
  paidFeesCount: number
  totalPaymentsMade: number
  fees: PathfinderFeeWithDetails[]
}

export interface DocumentCompletionStatus {
  pathfinder: Pathfinder
  totalRequired: number
  totalReceived: number
  completionPercentage: number
  missingDocuments: string[]
}
```

---

## Pinia Store Extensions

**File:** `src/stores/fundraiser.ts`

### Add State Variables

```typescript
const feeTypes = ref<FeeType[]>([])
const pathfinderFees = ref<PathfinderFee[]>([])
const payments = ref<Payment[]>([])
```

### Key Actions to Implement

**Fee Type Management:**
- `addFeeType()` - Create new fee type
- `updateFeeType()` - Edit fee type
- `deleteFeeType()` - Remove fee type

**Pathfinder Fee Management:**
- `assignFeeToPathfinder()` - Assign fee to single pathfinder
- `bulkAssignFee()` - Assign fee to multiple pathfinders
- `updatePathfinderFee()` - Update fee amount/due date/notes
- `waiveFee()` - Mark fee as waived
- `deletePathfinderFee()` - Remove fee assignment

**Payment Management:**
- `addPayment()` - Record new payment (triggers update to PathfinderFee via database trigger)
- `deletePayment()` - Remove payment (triggers revert via database trigger)

**Document Management:**
- `updateDocumentStatus()` - Update single document status for pathfinder
- `bulkUpdateDocumentStatus()` - Update document status for multiple pathfinders
- `getRequiredDocuments()` - Get required document list based on pathfinder type

### Key Computed Properties

```typescript
const pathfinderFinancialSummaries = computed((): PathfinderFinancialSummary[] => {
  // Aggregates fees and payments per pathfinder
})

const totalOutstandingBalance = computed(() => {
  return pathfinderFees.value.reduce((sum, fee) => sum + fee.AmountRemaining, 0)
})

const totalCollected = computed(() => {
  return pathfinderFees.value.reduce((sum, fee) => sum + fee.AmountPaid, 0)
})

const overdueFeesCount = computed(() => {
  return pathfinderFees.value.filter(fee => fee.Status === 'overdue').length
})

const documentCompletionStatuses = computed((): DocumentCompletionStatus[] => {
  // Calculates document completion % per pathfinder based on type requirements
})

const pathfindersWithIncompleteDocuments = computed(() => {
  return documentCompletionStatuses.value.filter(status => status.completionPercentage < 100)
})
```

### Export Functions

```typescript
const exportFinancialReport = () => {
  // CSV export with columns: Name, Type, Total Fees, Total Owed, Paid, Remaining, Overdue Count
}

const exportDocumentReport = () => {
  // CSV export with columns: Name, Type, Required Docs, Received Docs, Completion %, Missing Docs
}
```

---

## User Role System Extension

### 1. Update useAuth Composable

**File:** `src/composables/useAuth.ts`

```typescript
export type UserRole = 'admin' | 'user' | 'treasurer' | 'secretary'

interface CurrentUser {
  email: string | undefined
  id: string
  role: UserRole
}

const currentUser = ref<CurrentUser | null>(null)

export const useAuth = () => {
  // ... existing code ...

  const userRole = computed(() => currentUser.value?.role || 'user')
  const isAdmin = computed(() => currentUser.value?.role === 'admin')
  const isTreasurer = computed(() => currentUser.value?.role === 'treasurer' || currentUser.value?.role === 'admin')
  const isSecretary = computed(() => currentUser.value?.role === 'secretary' || currentUser.value?.role === 'admin')

  const initializeAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      currentUser.value = {
        email: session.user.email,
        id: session.user.id,
        role: (session.user.user_metadata?.role as UserRole) || 'user'
      }
      // ... save to localStorage ...
    }
  }

  const hasRole = (roles: UserRole | UserRole[]): boolean => {
    if (!currentUser.value) return false
    const roleArray = Array.isArray(roles) ? roles : [roles]
    return roleArray.includes(currentUser.value.role)
  }

  return {
    currentUser,
    isAuthenticated,
    userRole,
    isAdmin,
    isTreasurer,
    isSecretary,
    hasRole,
    // ... other exports ...
  }
}
```

### 2. Update UserManagement.vue

**File:** `src/views/UserManagement.vue`

Update role options:

```typescript
const roleOptions = ref([
  { label: 'Usuário', value: 'user' },
  { label: 'Administrador', value: 'admin' },
  { label: 'Tesoureiro', value: 'treasurer' },
  { label: 'Secretário', value: 'secretary' }
])
```

Add helper functions for role labels and severity badges.

### 3. Add Route Guards

**File:** `src/router/index.ts`

Add new routes with role requirements:

```typescript
{
  path: '/financial',
  name: 'financial',
  component: () => import('../views/FinancialTracking.vue'),
  meta: { requiresRole: ['admin', 'treasurer'] }
},
{
  path: '/documents',
  name: 'documents',
  component: () => import('../views/DocumentTracking.vue'),
  meta: { requiresRole: ['admin', 'secretary'] }
}
```

Add navigation guard:

```typescript
router.beforeEach((to, from, next) => {
  const { currentUser, hasRole } = useAuth()

  if (to.meta.requiresRole) {
    const requiredRoles = to.meta.requiresRole as UserRole[]
    if (!currentUser.value) {
      next('/login')
    } else if (!hasRole(requiredRoles)) {
      next('/')  // Redirect to dashboard if lacking role
    } else {
      next()
    }
  } else {
    next()
  }
})
```

---

## Navigation Updates

**File:** `src/config/navigation.ts`

Add new "Membros" section with role requirements:

```typescript
export interface MenuItem {
  path: string
  label: string
  icon: string
  requiredRoles?: ('admin' | 'user' | 'treasurer' | 'secretary')[]
}

export const menuSections: MenuSection[] = [
  {
    title: 'Operações',
    icon: 'pi pi-briefcase',
    items: [
      { path: '/', label: 'Dashboard', icon: 'pi pi-home' },
      { path: '/orders', label: 'Novo Pedido', icon: 'pi pi-plus' },
      { path: '/kitchen', label: 'Cozinha', icon: 'pi pi-stopwatch' }
    ]
  },
  {
    title: 'Gestão',
    icon: 'pi pi-cog',
    items: [
      { path: '/pathfinders', label: 'Desbravadores', icon: 'pi pi-users' },
      { path: '/products', label: 'Produtos', icon: 'pi pi-box' },
      { path: '/campaigns', label: 'Campanhas', icon: 'pi pi-flag' },
      { path: '/users', label: 'Usuários', icon: 'pi pi-user-plus', requiredRoles: ['admin'] }
    ]
  },
  {
    title: 'Membros',
    icon: 'pi pi-id-card',
    items: [
      { path: '/financial', label: 'Financeiro', icon: 'pi pi-dollar', requiredRoles: ['admin', 'treasurer'] },
      { path: '/documents', label: 'Documentos', icon: 'pi pi-file-check', requiredRoles: ['admin', 'secretary'] }
    ]
  },
  {
    title: 'Relatórios',
    icon: 'pi pi-chart-bar',
    items: [
      { path: '/leaderboard', label: 'Ranking', icon: 'pi pi-trophy' },
      { path: '/cost-calculation', label: 'Custos', icon: 'pi pi-calculator' }
    ]
  }
]
```

**Update AppSidebar.vue** to filter menu items by role:

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { menuSections } from '@/config/navigation'
import { useAuth } from '@/composables/useAuth'

const { hasRole } = useAuth()

const visibleMenuSections = computed(() => {
  return menuSections.filter(section => {
    return section.items.some(item => {
      if (!item.requiredRoles) return true
      return hasRole(item.requiredRoles)
    })
  })
})

const visibleMenuItems = (items: MenuItem[]) => {
  return items.filter(item => {
    if (!item.requiredRoles) return true
    return hasRole(item.requiredRoles)
  })
}
</script>

<template>
  <!-- Loop through visibleMenuSections and visibleMenuItems(section.items) -->
</template>
```

---

## New Views

### 1. FinancialTracking.vue (Treasurer Screen)

**File:** `src/views/FinancialTracking.vue`

**Key Features:**
- **Summary Cards**: Total Outstanding Balance, Total Collected, Overdue Count
- **Main DataTable**: Shows all pathfinders with columns:
  - Name, Type (Tag), Total Owed, Amount Paid, Balance Remaining, Overdue Count (Tag), Status (Tag)
  - Action buttons: View Details, Add Payment
- **Filters**: Name search, Payment status dropdown (all/pending/partial/overdue/paid), Pathfinder type
- **Fee Types Management Section**: DataTable of all fee types with add/edit/delete
- **Dialogs**:
  - Add Fee Type: Name, Description, Amount, Category, Recurrence, Applies To, Due Date, Year
  - Bulk Assign Fee: Select fee type, select pathfinders (multi-select), set due date
  - Add Payment: Select pathfinder fee, amount, payment method, date, notes, receipt number
  - Pathfinder Details: Show fee list with payment history timeline
- **Export Button**: exportFinancialReport() CSV download

**UI Pattern:** Follow existing management screens:
- PrimeVue DataTable with pagination (10 rows)
- Dialog modals (500-700px width)
- Form validation with `submitted` flag
- Toast notifications for actions
- Tag components for status display
- Confirmation dialogs for deletions

### 2. DocumentTracking.vue (Secretary Screen)

**File:** `src/views/DocumentTracking.vue`

**Key Features:**
- **Summary Cards**: Total Members, Complete Count, Incomplete Count
- **Main DataTable**: Shows all pathfinders with columns:
  - Expander, Name, Type (Tag), Registration Year, Progress Bar (completion %), Missing Count (Tag), Status (Tag)
  - Expandable row shows document checklist with inline checkboxes
- **Filters**: Name search, Pathfinder type, Completion status (all/complete/incomplete), Registration year
- **Document Checklist** (in expandable row):
  - Checkboxes for each required document based on pathfinder type
  - Tag showing received/missing status
  - Last updated date
  - Expiry warning for criminal background checks
- **Dialogs**:
  - Bulk Update: Select multiple pathfinders, select document, set status (received/missing)
- **Export Button**: exportDocumentReport() CSV download

**Document Requirements Logic:**
```typescript
const getRequiredDocuments = (type: Pathfinder['Type']) => {
  const common = ['id_cpf', 'sus_card', 'proof_residence']
  if (type === 'desbravador') {
    return [...common, 'parent_id_cpf', 'vaccination_card']
  } else if (type === 'staff' || type === 'directors') {
    return [...common, 'criminal_background']
  }
  return common
}
```

---

## Update PathfinderManagement.vue

**File:** `src/views/PathfinderManagement.vue`

Extend the pathfinder form to include new fields:

```typescript
const pathfinderForm = ref({
  Name: '',
  Type: 'desbravador' as 'desbravador' | 'staff' | 'directors',
  Email: '',
  Phone: '',
  ParentName: '',
  ParentEmail: '',
  ParentPhone: '',
  BirthDate: null as Date | null,
  Address: '',
  Notes: '',
  IsActive: true,
  RegistrationYear: new Date().getFullYear()
})
```

Update DataTable to show Type column with Tag display.

---

## Critical Files Summary

1. **db/FINANCIAL-DOCUMENT-TRACKING-MIGRATION.sql** - Database migration (run in Supabase first)
2. **src/stores/fundraiser.ts** - Core business logic (interfaces, state, CRUD actions, computed properties, exports)
3. **src/composables/useAuth.ts** - Role system (new role types, role checks, hasRole helper)
4. **src/views/FinancialTracking.vue** - Treasurer interface (financial tracking UI)
5. **src/views/DocumentTracking.vue** - Secretary interface (document tracking UI)
6. **src/config/navigation.ts** - Menu structure (new "Membros" section with role requirements)
7. **src/layout/AppSidebar.vue** - Navigation filtering (role-based menu visibility)
8. **src/router/index.ts** - Route guards (role-based access control)
9. **src/views/UserManagement.vue** - Role management (extended role options)
10. **src/views/PathfinderManagement.vue** - Extended pathfinder form (new fields)

---

## Implementation Sequence

### Phase 1: Database & Backend (Foundation)
1. Run SQL migration in Supabase (db/FINANCIAL-DOCUMENT-TRACKING-MIGRATION.sql)
2. Test triggers in Supabase dashboard (insert payments, verify fee updates)

### Phase 2: TypeScript Interfaces & Store
1. Add all new interfaces to fundraiser.ts
2. Extend Pathfinder interface with new fields
3. Add state refs for feeTypes, pathfinderFees, payments
4. Update loadFromSupabase to load new tables
5. Implement all CRUD actions (fee types, pathfinder fees, payments, documents)
6. Implement computed properties for summaries
7. Implement CSV export functions
8. Test store actions in browser console

### Phase 3: User Role System
1. Update useAuth with new role types and helpers
2. Update UserManagement.vue with new role options
3. Add route guards to router
4. Update navigation.ts with "Membros" section
5. Update AppSidebar.vue with role filtering
6. Test role-based access (login as treasurer/secretary)

### Phase 4: Financial Tracking UI
1. Create FinancialTracking.vue skeleton
2. Implement summary cards
3. Implement pathfinder financial DataTable with filters
4. Create AddFeeTypeDialog
5. Create BulkAssignFeeDialog
6. Create AddPaymentDialog
7. Create PathfinderDetailsDialog with payment timeline
8. Wire all actions to store
9. Test all CRUD operations

### Phase 5: Document Tracking UI
1. Create DocumentTracking.vue skeleton
2. Implement summary cards
3. Implement pathfinder document DataTable with filters
4. Implement expandable rows with document checklist
5. Create BulkUpdateDocumentDialog
6. Wire document updates to store
7. Test document status updates

### Phase 6: Pathfinder Management Updates
1. Extend pathfinderForm with new fields
2. Update dialog layout with two-column form
3. Add Type dropdown (desbravador/staff/directors)
4. Update DataTable columns
5. Test creating/editing pathfinders with new fields

### Phase 7: Integration & Testing
1. Test navigation between all screens
2. Test role-based menu visibility
3. Test CSV exports
4. Test payment triggers (verify fee status updates)
5. Test document completion calculations
6. Performance testing with sample data
7. Mobile responsiveness testing

---

## Verification Approach

### Database Testing

Test payment trigger flow in Supabase SQL Editor - see migration file for test queries.

### Store Testing

```typescript
const store = useFundraiserStore()

// Test adding fee type
const feeType = await store.addFeeType({
  Name: 'DSA Campuri 2026',
  Amount: 150.00,
  FeeCategory: 'event',
  RecurrenceType: 'one-time',
  DueDate: '2026-04-30',
  AppliesTo: ['desbravador'],
  IsActive: true,
  Year: 2026
})

// Test bulk assign
const pathfinderIds = store.pathfinders
  .filter(p => p.Type === 'desbravador' && p.IsActive)
  .map(p => p.PK)
await store.bulkAssignFee(feeType.PK, pathfinderIds, '2026-04-30')

// Test adding payment
await store.addPayment({
  PathfinderId: 'PATHFINDER#xxx',
  PathfinderFeeId: 'PATHFINDERFEE#zzz',
  Amount: 50.00,
  PaymentMethod: 'cash',
  PaymentDate: '2026-02-06'
})

// Verify computed properties
console.log('Outstanding:', store.totalOutstandingBalance)
console.log('Collected:', store.totalCollected)
console.log('Overdue:', store.overdueFeesCount)
```

### UI Testing Checklist

- [ ] Treasurer can access /financial, others cannot
- [ ] Secretary can access /documents, others cannot
- [ ] Admin can access all screens
- [ ] Menu shows "Membros" section only to treasurer/secretary/admin
- [ ] Summary cards display correct totals
- [ ] DataTable filters work (name, type, status)
- [ ] Add fee type dialog validates required fields
- [ ] Bulk assign fee shows correct pathfinder list
- [ ] Add payment updates fee status in UI immediately
- [ ] Payment history timeline displays correctly
- [ ] Document checkboxes update status on click
- [ ] Progress bars show correct completion percentage
- [ ] CSV export downloads with correct data
- [ ] Toast notifications appear for all actions
- [ ] Mobile responsive layout works

---

## Edge Cases & Error Handling

1. **Payment exceeds remaining**: Show warning, allow override or cap at remaining
2. **Duplicate fee assignment**: Database constraint prevents, show friendly error
3. **Delete fee type with assigned fees**: Show warning with count, CASCADE delete
4. **Inactive pathfinder gets fee**: Allow but show warning in bulk assign
5. **Document type doesn't apply**: UI only shows relevant documents per type
6. **Negative balance**: Database CHECK constraint prevents
7. **Payment deletion**: Confirmation dialog, trigger reverts PathfinderFee amounts
8. **Overdue fee**: Trigger auto-marks as overdue when DueDate passes

---

## Notes

- **Payment allocation**: No automatic allocation. Treasurer explicitly selects which PathfinderFee to pay toward when adding payment.
- **Fee recurrence**: Monthly fees are manually created and bulk assigned by treasurer each month. No auto-creation in Phase 1.
- **Document storage**: Checkbox tracking only - no file uploads. Physical documents stored elsewhere.
- **Notifications**: Visual indicators only (badges, tags). Email/SMS notifications are future enhancements.
- **Performance**: Client-side pagination suitable for <1000 pathfinders. Monitor and switch to server-side if needed.
- **Expiry tracking**: Criminal background checks include optional expiry date. UI shows warnings 60 days before expiry.

---

## Success Criteria

✅ Treasurer can create fee types and assign to pathfinders
✅ Treasurer can record payments and see updated balances
✅ Treasurer can view financial summary with outstanding/collected totals
✅ Treasurer can export financial report to CSV
✅ Secretary can view document completion status per pathfinder
✅ Secretary can update document status with inline checkboxes
✅ Secretary can export document report to CSV
✅ Admin can assign treasurer and secretary roles to users
✅ Navigation menu filters based on user role
✅ Payment triggers automatically update fee status and amounts
✅ Document completion percentage calculates correctly per pathfinder type
