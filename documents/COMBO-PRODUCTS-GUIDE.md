# Combo Products Implementation Guide

## ✅ What's Been Implemented

### 1. **Database Changes**
- Added `ComboItems` JSONB column to ProductsTable
- Added `Description` TEXT column for product descriptions
- Created validation trigger to ensure combo items reference valid products
- Created helper function `get_combo_contents()` to expand combo items

**Migration file:** `combo-products-migration.sql`

### 2. **Product Interface Updates**
- Added `ComboItem` interface with:
  - `ProductId`: Reference to product
  - `Quantity`: How many of this product
  - `AllowFlavorSelection`: Whether flavor can be chosen
- Updated `Product` interface with:
  - `Description?`: Optional description
  - `ComboItems?`: Array of combo items

### 3. **Products Management UI**
✅ Create combo products with category "combo"
✅ Add multiple items to a combo
✅ Set quantity for each item
✅ Allow/disallow flavor selection per item
✅ Display combo contents on product cards
✅ Prevent adding combos to other combos (only regular products)

## 📋 How to Use

### Step 1: Run Database Migration
Execute `combo-products-migration.sql` in your Supabase SQL editor.

### Step 2: Create a Combo Product
1. Go to "Produtos" (Products Management)
2. Click "Novo Produto"
3. Set:
   - **Name**: "Combo 1 - Pizza + Pastel"
   - **Price**: 13.00 (fixed price)
   - **Category**: Combo
   - **Description**: "1 Mini Pizza + 1 Pastel - Escolha os sabores!"

4. Add Combo Items:
   - Click "Adicionar Item"
   - Select Product: "Mini Pizza"
   - Quantity: 1
   - ✓ Permitir escolha de sabor (checked)

   - Click "Adicionar Item" again
   - Select Product: "Pastel"
   - Quantity: 1
   - ✓ Permitir escolha de sabor (checked)

5. Save!

### Step 3: Order Entry with Combos
When you add a combo to an order:
- Select the combo product
- If `AllowFlavorSelection` is true for an item, you'll be able to choose flavors
- Price is fixed (13.00 in this example)

### Step 4: Kitchen Display
Kitchen will see:
```
Combo 1 - Pizza + Pastel
  - 1x Mini Pizza (Margherita)
  - 1x Pastel (Carne)
```

## 🔧 Next Steps (TODO)

### OrderEntry Enhancement
Need to update OrderEntry.vue to:
1. Detect when selected product is a combo
2. Show combo item flavor selectors (for items with `AllowFlavorSelection = true`)
3. Store flavor selections properly

### Kitchen Display Enhancement
Update Kitchen.vue to:
1. Expand combo products to show individual items
2. Display "Combo 1:" followed by the items list

## 💡 Example Combos

**Combo 1 - Pizza + Pastel**
- Price: R$ 13.00
- Items:
  - 1x Mini Pizza (with flavor selection)
  - 1x Pastel (with flavor selection)

**Combo Família**
- Price: R$ 45.00
- Items:
  - 3x Mini Pizza (with flavor selection)
  - 2x Pastel (with flavor selection)
  - 2x Bebida (no flavor selection)

**Combo Econômico**
- Price: R$ 20.00
- Items:
  - 2x Pastel (with flavor selection)
  - 1x Sorvete (with flavor selection)

## 🎯 Benefits
- ✅ Fixed pricing - you control the combo price
- ✅ Flexible configuration - any combination of products
- ✅ Flavor selection support per item
- ✅ Easy to create and manage
- ✅ Kitchen sees exactly what to prepare
- ✅ Works with existing order and campaign system