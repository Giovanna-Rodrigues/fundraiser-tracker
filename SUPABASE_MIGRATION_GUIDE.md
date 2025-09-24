# 🔄 Supabase Migration Guide

## ✅ What's Been Done

### 1. Database Schema Created ✓
- Created `supabase-schema.sql` with all tables
- Auto-generates PK/SK with UUID format (e.g., `PATHFINDER#550e8400-...`)
- Tables: PathfindersTable, ProductsTable, OrdersTable, OrderItemsTable
- RLS policies configured

### 2. TypeScript Interfaces Updated ✓
- Changed from `id: number` to `PK: string` and `SK: string`
- All field names now use PascalCase (e.g., `Name`, `Price`, `CustomerName`)
- Store at `src/stores/fundraiser.ts` updated with Supabase methods

### 3. Store Methods Converted ✓
- `loadFromSupabase()` - loads all data from Supabase
- `addPathfinder()`, `updatePathfinder()`, `deletePathfinder()` - async methods
- `addProduct()`, `updateProduct()`, `deleteProduct()` - async methods
- `addOrder()`, `updateOrder()`, `deleteOrder()` - async methods
- All methods now use Supabase client instead of localStorage

## ⚠️ Known Issues

### 1. **OrderItems Structure Changed**
- **OLD**: Orders had an `items` array property
- **NEW**: OrderItems are stored in a separate `OrderItemsTable`
- **Impact**: Need to handle OrderItems separately when creating/loading orders

### 2. **Field Name Changes**
All components need to update field references:

| Old (camelCase) | New (PascalCase) |
|-----------------|------------------|
| `id` | `PK` |
| `name` | `Name` |
| `createdAt` | `CreatedAt` |
| `pathfinderId` | `PathfinderId` |
| `customerName` | `CustomerName` |
| `totalAmount` | `TotalAmount` |
| `subtotal` | `Subtotal` |
| `discount` | `Discount` |
| `paymentMethod` | `PaymentMethod` |
| `status` | `Status` |
| `date` | `Date` |
| `notes` | `Notes` |
| `price` | `Price` |
| `category` | `Category` |
| `flavors` | `Flavors` |
| `productId` | `ProductId` |
| `quantity` | `Quantity` |
| `flavor` | `Flavor` |
| `unitPrice` | `UnitPrice` |
| `totalPrice` | `TotalPrice` |

### 3. **Components with Errors** (70+ TypeScript errors)
Need to update:
- `src/views/Dashboard.vue`
- `src/views/Kitchen.vue`
- `src/views/Leaderboard.vue`
- `src/views/OrderEntry.vue`
- `src/views/PathfinderManagement.vue`
- `src/views/SalesList.vue`

## 📋 Next Steps

### Option A: Complete Migration (Recommended)
1. **Update OrderItems handling**
   - Modify `addOrder()` to also insert OrderItems
   - Load OrderItems when fetching orders
   - Update computed properties to join OrderItems

2. **Fix all Vue components**
   - Update field names from camelCase to PascalCase
   - Update method calls to use `PK` instead of `id`
   - Make method calls async/await

3. **Test authentication**
   - Ensure users can login to Supabase
   - Test RLS policies

### Option B: Hybrid Approach
Keep using localStorage for now, but prepare for migration:
1. Create adapter functions to convert between formats
2. Gradually migrate features one by one

## 🔧 Quick Fixes Needed

### Store Methods to Add
```typescript
// Load order items for an order
const loadOrderItems = async (orderId: string): Promise<OrderItem[]> => {
  const { data, error } = await supabase
    .from('OrderItemsTable')
    .select('*')
    .eq('OrderId', orderId)

  if (error) throw error
  return data || []
}

// Add order with items
const addOrderWithItems = async (order, items: OrderItem[]) => {
  // 1. Create order
  // 2. Create order items
  // 3. Return combined result
}
```

### Component Update Example
```diff
- const pathfinder = pathfinders.value.find(p => p.id === order.pathfinderId)
+ const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)

- {{ order.customerName }}
+ {{ order.CustomerName }}

- fundraiserStore.updateOrder(order.id, { status: 'ready' })
+ await fundraiserStore.updateOrder(order.PK, { Status: 'ready' })
```

## 💡 Recommendations

1. **Start with PathfinderManagement** - Simplest component to update
2. **Then Products** - Similar pattern
3. **Then Orders** - Most complex due to OrderItems
4. **Finally Dashboard/Kitchen** - Uses computed data from orders

Would you like me to:
- A) Update all components automatically (will take ~15 minutes)
- B) Update one component at a time so you can see the pattern
- C) Create a compatibility layer to use both old and new formats