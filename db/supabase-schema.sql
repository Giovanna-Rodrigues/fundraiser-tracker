-- ============================================
-- SUPABASE SCHEMA - FUNDRAISER TRACKER
-- ============================================
-- This script creates all tables with auto-generated PK/SK patterns
-- Pattern: PATHFINDER#<uuid>, PRODUCT#<uuid>, ORDER#<uuid>, etc.
-- Includes: Campaigns and Combo Products functionality
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
-- 3. CREATE CAMPAIGNS TABLE
-- ============================================

DROP TABLE IF EXISTS "CampaignsTable" CASCADE;

CREATE TABLE "CampaignsTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "StartDate" DATE NOT NULL,
  "EndDate" DATE NOT NULL,
  "Status" TEXT DEFAULT 'planned' CHECK ("Status" IN ('planned', 'active', 'completed')),
  "Goal" NUMERIC(10,2),
  "Description" TEXT,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate Campaign PK/SK
CREATE OR REPLACE FUNCTION generate_campaign_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'CAMPAIGN#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for CampaignsTable
DROP TRIGGER IF EXISTS campaign_pk_trigger ON "CampaignsTable";
CREATE TRIGGER campaign_pk_trigger
  BEFORE INSERT ON "CampaignsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_campaign_pk();

-- ============================================
-- 4. CREATE OR UPDATE PRODUCTS TABLE (WITH COMBO SUPPORT)
-- ============================================

-- Drop table if exists to recreate with proper constraints
DROP TABLE IF EXISTS "ProductsTable" CASCADE;

-- Create ProductsTable with Combo support
CREATE TABLE "ProductsTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "Price" NUMERIC(10,2) NOT NULL,
  "Category" TEXT NOT NULL,
  "Flavors" TEXT[],
  "Description" TEXT,
  "ComboItems" JSONB,
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

-- Validation function for combo items
CREATE OR REPLACE FUNCTION validate_combo_items()
RETURNS TRIGGER AS $$
DECLARE
  item JSONB;
  product_exists BOOLEAN;
BEGIN
  IF NEW."ComboItems" IS NOT NULL THEN
    FOR item IN SELECT * FROM jsonb_array_elements(NEW."ComboItems")
    LOOP
      SELECT EXISTS(
        SELECT 1 FROM "ProductsTable"
        WHERE "PK" = (item->>'ProductId')::TEXT
      ) INTO product_exists;

      IF NOT product_exists THEN
        RAISE EXCEPTION 'Invalid ProductId in ComboItems: %', item->>'ProductId';
      END IF;

      IF (item->>'Quantity')::INT < 1 THEN
        RAISE EXCEPTION 'Quantity must be at least 1 in ComboItems';
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate combo items
DROP TRIGGER IF EXISTS validate_combo_items_trigger ON "ProductsTable";
CREATE TRIGGER validate_combo_items_trigger
  BEFORE INSERT OR UPDATE ON "ProductsTable"
  FOR EACH ROW
  EXECUTE FUNCTION validate_combo_items();

-- ============================================
-- 5. CREATE ORDERS TABLE (WITH CAMPAIGN SUPPORT)
-- ============================================

DROP TABLE IF EXISTS "OrdersTable" CASCADE;

CREATE TABLE "OrdersTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "UserId" UUID REFERENCES auth.users(id),
  "PathfinderId" TEXT REFERENCES "PathfindersTable"("PK"),
  "CampaignId" TEXT REFERENCES "CampaignsTable"("PK"),
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

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_orders_campaign
  ON "OrdersTable"("CampaignId");

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
-- 6. CREATE ORDER ITEMS TABLE
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
-- 7. CREATE PRICE HISTORY TABLE
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

-- ============================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE "PathfindersTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "CampaignsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ProductsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "OrdersTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "OrderItemsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PriceHistoryTable" ENABLE ROW LEVEL SECURITY;

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

-- CampaignsTable Policies
DROP POLICY IF EXISTS "campaigns_select" ON "CampaignsTable";
CREATE POLICY "campaigns_select" ON "CampaignsTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "campaigns_insert" ON "CampaignsTable";
CREATE POLICY "campaigns_insert" ON "CampaignsTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "campaigns_update" ON "CampaignsTable";
CREATE POLICY "campaigns_update" ON "CampaignsTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "campaigns_delete" ON "CampaignsTable";
CREATE POLICY "campaigns_delete" ON "CampaignsTable"
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
-- 9. HELPER FUNCTIONS
-- ============================================

-- Function to get active campaign
CREATE OR REPLACE FUNCTION get_active_campaign()
RETURNS TEXT AS $$
DECLARE
  active_campaign_id TEXT;
BEGIN
  SELECT "PK" INTO active_campaign_id
  FROM "CampaignsTable"
  WHERE "Status" = 'active'
  ORDER BY "StartDate" DESC
  LIMIT 1;

  RETURN active_campaign_id;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-complete past campaigns
CREATE OR REPLACE FUNCTION auto_complete_campaigns()
RETURNS void AS $$
BEGIN
  UPDATE "CampaignsTable"
  SET "Status" = 'completed'
  WHERE "Status" = 'active'
    AND "EndDate" < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function to get combo contents
CREATE OR REPLACE FUNCTION get_combo_contents(combo_product_id TEXT)
RETURNS TABLE (
  product_id TEXT,
  product_name TEXT,
  quantity INT,
  allow_flavor_selection BOOLEAN,
  product_price NUMERIC,
  product_flavors TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (item->>'ProductId')::TEXT as product_id,
    p."Name" as product_name,
    (item->>'Quantity')::INT as quantity,
    COALESCE((item->>'AllowFlavorSelection')::BOOLEAN, false) as allow_flavor_selection,
    p."Price" as product_price,
    p."Flavors" as product_flavors
  FROM "ProductsTable" combo
  CROSS JOIN LATERAL jsonb_array_elements(combo."ComboItems") as item
  LEFT JOIN "ProductsTable" p ON p."PK" = (item->>'ProductId')::TEXT
  WHERE combo."PK" = combo_product_id
    AND combo."ComboItems" IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 10. CREATE DEFAULT CAMPAIGN FOR EXISTING DATA
-- ============================================

-- Insert a default campaign for existing orders
INSERT INTO "CampaignsTable" ("Name", "StartDate", "EndDate", "Status", "Description")
VALUES (
  'Campanha Inicial',
  '2024-01-01',
  '2025-12-31',
  'active',
  'Campanha criada automaticamente para pedidos existentes'
)
ON CONFLICT DO NOTHING;

-- Update existing orders to belong to the default campaign
UPDATE "OrdersTable"
SET "CampaignId" = (SELECT "PK" FROM "CampaignsTable" WHERE "Name" = 'Campanha Inicial')
WHERE "CampaignId" IS NULL;

-- ============================================
-- 11. INSERT INITIAL PRODUCTS (OPTIONAL)
-- ============================================

-- Uncomment to insert default products:
-- INSERT INTO "ProductsTable" ("Name", "Price", "Category", "Flavors", "Description") VALUES
-- ('Mini Pizza', 6.00, 'pizza', ARRAY['Margherita', 'Pepperoni', 'Calabresa', 'Frango', 'Portuguesa', 'Vegetariana'], 'Mini pizza individual com diversos sabores'),
-- ('Pastel', 9.00, 'pastry', ARRAY['Carne', 'Queijo', 'Pizza', 'Frango', 'Palmito', 'Doce de Leite'], 'Pastel frito crocante'),
-- ('Sorvete', 5.00, 'ice-cream', ARRAY['Chocolate', 'Morango', 'Baunilha', 'Napolitano', 'Coco', 'Açaí'], 'Sorvete cremoso');

-- Example Combo Product (uncomment and adjust product IDs):
-- INSERT INTO "ProductsTable" ("Name", "Price", "Category", "Description", "ComboItems")
-- VALUES (
--   'Combo 1 - Pizza + Pastel',
--   13.00,
--   'combo',
--   '1 Mini Pizza + 1 Pastel - Escolha os sabores!',
--   '[
--     {"ProductId": "PRODUCT#your-pizza-id", "Quantity": 1, "AllowFlavorSelection": true},
--     {"ProductId": "PRODUCT#your-pastel-id", "Quantity": 1, "AllowFlavorSelection": true}
--   ]'::jsonb
-- );

-- ============================================
-- DONE!
-- ============================================
-- All tables created with auto-generating PK/SK
-- Pattern: PATHFINDER#<uuid>
--         CAMPAIGN#<uuid>
--         PRODUCT#<uuid>
--         ORDER#<uuid>
--         ORDERITEM#<uuid>
--         PRICEHISTORY#<uuid>
--
-- Features included:
-- ✅ Pathfinders management
-- ✅ Campaign tracking (monthly/periodic fundraisers)
-- ✅ Products with flavors
-- ✅ Combo/Bundle products with flavor selection
-- ✅ Orders with campaign assignment
-- ✅ Order items tracking
-- ✅ Price history
-- ✅ Row Level Security (RLS)
-- ✅ Helper functions
-- ============================================