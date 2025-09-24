-- ============================================
-- SUPABASE SCHEMA - FUNDRAISER TRACKER
-- ============================================
-- This script creates all tables with auto-generated PK/SK patterns
-- Pattern: PATHFINDER#<uuid>, PRODUCT#<uuid>, ORDER#<uuid>, etc.
-- ============================================

-- ============================================
-- 1. ENABLE UUID EXTENSION
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. CREATE OR UPDATE PATHFINDERS TABLE
-- ============================================

-- Drop table if exists to recreate with proper constraints
DROP TABLE IF EXISTS "PathfindersTable" CASCADE;

-- Create PathfindersTable
CREATE TABLE "PathfindersTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate Pathfinder PK/SK
CREATE OR REPLACE FUNCTION generate_pathfinder_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'PATHFINDER#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for PathfindersTable
DROP TRIGGER IF EXISTS pathfinder_pk_trigger ON "PathfindersTable";
CREATE TRIGGER pathfinder_pk_trigger
  BEFORE INSERT ON "PathfindersTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_pathfinder_pk();

-- ============================================
-- 3. CREATE OR UPDATE PRODUCTS TABLE
-- ============================================

-- Drop table if exists to recreate with proper constraints
DROP TABLE IF EXISTS "ProductsTable" CASCADE;

-- Create ProductsTable
CREATE TABLE "ProductsTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "Price" NUMERIC(10,2) NOT NULL,
  "Category" TEXT NOT NULL,
  "Flavors" TEXT[], -- Array of flavors
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate Product PK/SK
CREATE OR REPLACE FUNCTION generate_product_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'PRODUCT#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for ProductsTable
DROP TRIGGER IF EXISTS product_pk_trigger ON "ProductsTable";
CREATE TRIGGER product_pk_trigger
  BEFORE INSERT ON "ProductsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_product_pk();

-- ============================================
-- 4. CREATE ORDERS TABLE
-- ============================================

DROP TABLE IF EXISTS "OrdersTable" CASCADE;

CREATE TABLE "OrdersTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "UserId" UUID REFERENCES auth.users(id),
  "PathfinderId" TEXT REFERENCES "PathfindersTable"("PK"),
  "CustomerName" TEXT NOT NULL,
  "Subtotal" NUMERIC(10,2) NOT NULL,
  "Discount" NUMERIC(10,2) DEFAULT 0,
  "TotalAmount" NUMERIC(10,2) NOT NULL,
  "PaymentMethod" TEXT NOT NULL,
  "Status" TEXT DEFAULT 'pending',
  "Date" DATE NOT NULL,
  "Notes" TEXT,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate Order PK/SK
CREATE OR REPLACE FUNCTION generate_order_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'ORDER#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for OrdersTable
DROP TRIGGER IF EXISTS order_pk_trigger ON "OrdersTable";
CREATE TRIGGER order_pk_trigger
  BEFORE INSERT ON "OrdersTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_order_pk();

-- ============================================
-- 5. CREATE ORDER ITEMS TABLE
-- ============================================

DROP TABLE IF EXISTS "OrderItemsTable" CASCADE;

CREATE TABLE "OrderItemsTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "OrderId" TEXT REFERENCES "OrdersTable"("PK") ON DELETE CASCADE,
  "ProductId" TEXT REFERENCES "ProductsTable"("PK"),
  "Quantity" INTEGER NOT NULL,
  "Flavor" TEXT,
  "UnitPrice" NUMERIC(10,2) NOT NULL,
  "TotalPrice" NUMERIC(10,2) NOT NULL,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate OrderItem PK/SK
CREATE OR REPLACE FUNCTION generate_order_item_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'ORDERITEM#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for OrderItemsTable
DROP TRIGGER IF EXISTS order_item_pk_trigger ON "OrderItemsTable";
CREATE TRIGGER order_item_pk_trigger
  BEFORE INSERT ON "OrderItemsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_order_item_pk();

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE "PathfindersTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ProductsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "OrdersTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "OrderItemsTable" ENABLE ROW LEVEL SECURITY;

-- PathfindersTable Policies
DROP POLICY IF EXISTS "pathfinders_select" ON "PathfindersTable";
CREATE POLICY "pathfinders_select" ON "PathfindersTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "pathfinders_insert" ON "PathfindersTable";
CREATE POLICY "pathfinders_insert" ON "PathfindersTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "pathfinders_update" ON "PathfindersTable";
CREATE POLICY "pathfinders_update" ON "PathfindersTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "pathfinders_delete" ON "PathfindersTable";
CREATE POLICY "pathfinders_delete" ON "PathfindersTable"
  FOR DELETE TO authenticated USING (true);

-- ProductsTable Policies
DROP POLICY IF EXISTS "products_select" ON "ProductsTable";
CREATE POLICY "products_select" ON "ProductsTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "products_insert" ON "ProductsTable";
CREATE POLICY "products_insert" ON "ProductsTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "products_update" ON "ProductsTable";
CREATE POLICY "products_update" ON "ProductsTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "products_delete" ON "ProductsTable";
CREATE POLICY "products_delete" ON "ProductsTable"
  FOR DELETE TO authenticated USING (true);

-- OrdersTable Policies (users can only access their own orders)
DROP POLICY IF EXISTS "orders_select" ON "OrdersTable";
CREATE POLICY "orders_select" ON "OrdersTable"
  FOR SELECT TO authenticated USING ("UserId" = auth.uid());

DROP POLICY IF EXISTS "orders_insert" ON "OrdersTable";
CREATE POLICY "orders_insert" ON "OrdersTable"
  FOR INSERT TO authenticated WITH CHECK ("UserId" = auth.uid());

DROP POLICY IF EXISTS "orders_update" ON "OrdersTable";
CREATE POLICY "orders_update" ON "OrdersTable"
  FOR UPDATE TO authenticated USING ("UserId" = auth.uid());

DROP POLICY IF EXISTS "orders_delete" ON "OrdersTable";
CREATE POLICY "orders_delete" ON "OrdersTable"
  FOR DELETE TO authenticated USING ("UserId" = auth.uid());

-- OrderItemsTable Policies (access through orders)
DROP POLICY IF EXISTS "order_items_select" ON "OrderItemsTable";
CREATE POLICY "order_items_select" ON "OrderItemsTable"
  FOR SELECT TO authenticated
  USING (
    "OrderId" IN (
      SELECT "PK" FROM "OrdersTable" WHERE "UserId" = auth.uid()
    )
  );

DROP POLICY IF EXISTS "order_items_insert" ON "OrderItemsTable";
CREATE POLICY "order_items_insert" ON "OrderItemsTable"
  FOR INSERT TO authenticated
  WITH CHECK (
    "OrderId" IN (
      SELECT "PK" FROM "OrdersTable" WHERE "UserId" = auth.uid()
    )
  );

DROP POLICY IF EXISTS "order_items_update" ON "OrderItemsTable";
CREATE POLICY "order_items_update" ON "OrderItemsTable"
  FOR UPDATE TO authenticated
  USING (
    "OrderId" IN (
      SELECT "PK" FROM "OrdersTable" WHERE "UserId" = auth.uid()
    )
  );

DROP POLICY IF EXISTS "order_items_delete" ON "OrderItemsTable";
CREATE POLICY "order_items_delete" ON "OrderItemsTable"
  FOR DELETE TO authenticated
  USING (
    "OrderId" IN (
      SELECT "PK" FROM "OrdersTable" WHERE "UserId" = auth.uid()
    )
  );

-- ============================================
-- 7. OPTIONAL: MIGRATE EXISTING DATA
-- ============================================

-- If you have existing data with numeric PK/SK, uncomment and run:
-- This will update existing records to use the new format

-- UPDATE "PathfindersTable"
-- SET "PK" = 'PATHFINDER#' || "PK", "SK" = 'PATHFINDER#' || "SK"
-- WHERE "PK" NOT LIKE 'PATHFINDER#%';

-- UPDATE "ProductsTable"
-- SET "PK" = 'PRODUCT#' || "PK", "SK" = 'PRODUCT#' || "SK"
-- WHERE "PK" NOT LIKE 'PRODUCT#%';

-- ============================================
-- 8. CREATE PRICE HISTORY TABLE
-- ============================================

DROP TABLE IF EXISTS "PriceHistoryTable" CASCADE;

CREATE TABLE "PriceHistoryTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "ProductId" TEXT REFERENCES "ProductsTable"("PK") ON DELETE CASCADE,
  "OrderId" TEXT REFERENCES "OrdersTable"("PK"),
  "Price" NUMERIC(10,2) NOT NULL,
  "EffectiveDate" TIMESTAMPTZ DEFAULT NOW(),
  "Notes" TEXT,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate PriceHistory PK/SK
CREATE OR REPLACE FUNCTION generate_price_history_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'PRICEHISTORY#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for PriceHistoryTable
DROP TRIGGER IF EXISTS price_history_pk_trigger ON "PriceHistoryTable";
CREATE TRIGGER price_history_pk_trigger
  BEFORE INSERT ON "PriceHistoryTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_price_history_pk();

-- Enable RLS on PriceHistoryTable
ALTER TABLE "PriceHistoryTable" ENABLE ROW LEVEL SECURITY;

-- PriceHistoryTable Policies
DROP POLICY IF EXISTS "price_history_select" ON "PriceHistoryTable";
CREATE POLICY "price_history_select" ON "PriceHistoryTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "price_history_insert" ON "PriceHistoryTable";
CREATE POLICY "price_history_insert" ON "PriceHistoryTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "price_history_update" ON "PriceHistoryTable";
CREATE POLICY "price_history_update" ON "PriceHistoryTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "price_history_delete" ON "PriceHistoryTable";
CREATE POLICY "price_history_delete" ON "PriceHistoryTable"
  FOR DELETE TO authenticated USING (true);

-- ============================================
-- 9. INSERT INITIAL PRODUCTS (OPTIONAL)
-- ============================================

-- Uncomment to insert default products:
-- INSERT INTO "ProductsTable" ("Name", "Price", "Category", "Flavors") VALUES
-- ('Mini Pizza', 15.00, 'pizza', ARRAY['Margherita', 'Pepperoni', 'Calabresa', 'Frango', 'Portuguesa', 'Vegetariana']),
-- ('Pastel', 15.00, 'pastry', ARRAY['Carne', 'Queijo', 'Pizza', 'Frango', 'Palmito', 'Doce de Leite']),
-- ('Sorvete', 5.00, 'ice-cream', ARRAY['Chocolate', 'Morango', 'Baunilha', 'Napolitano', 'Coco', 'Açaí']);

-- ============================================
-- DONE!
-- ============================================
-- All tables created with auto-generating PK/SK
-- Pattern: PATHFINDER#550e8400-e29b-41d4-a716-446655440000
--         PRODUCT#550e8400-e29b-41d4-a716-446655440001
--         ORDER#550e8400-e29b-41d4-a716-446655440002
--         ORDERITEM#550e8400-e29b-41d4-a716-446655440003
-- ============================================