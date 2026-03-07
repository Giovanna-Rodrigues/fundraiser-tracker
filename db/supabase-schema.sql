-- ============================================
-- SUPABASE SCHEMA - FUNDRAISER TRACKER
-- ============================================
-- This script creates all tables with auto-generated PK/SK patterns
-- Pattern: PATHFINDER#<uuid>, PRODUCT#<uuid>, ORDER#<uuid>, etc.
-- Includes: Campaigns, Combo Products, Financial Tracking, Document Management
-- ============================================

-- ============================================
-- 1. ENABLE UUID EXTENSION
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. CREATE PATHFINDERS TABLE
-- ============================================

DROP TABLE IF EXISTS "PathfindersTable" CASCADE;

CREATE TABLE "PathfindersTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "Type" TEXT DEFAULT 'desbravador' CHECK ("Type" IN ('desbravador', 'staff', 'directors')),
  "Email" TEXT,
  "Phone" TEXT,
  "ParentName" TEXT,
  "ParentEmail" TEXT,
  "ParentPhone" TEXT,
  "BirthDate" DATE,
  "Address" TEXT,
  "Notes" TEXT,
  "IsActive" BOOLEAN DEFAULT true,
  "RegistrationYear" INTEGER,
  "Documents" JSONB DEFAULT '{}'::jsonb,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
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

DROP TRIGGER IF EXISTS pathfinder_pk_trigger ON "PathfindersTable";
CREATE TRIGGER pathfinder_pk_trigger
  BEFORE INSERT ON "PathfindersTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_pathfinder_pk();

-- Trigger to auto-update UpdatedAt
CREATE OR REPLACE FUNCTION update_pathfinder_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."UpdatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pathfinder_updated_at_trigger ON "PathfindersTable";
CREATE TRIGGER pathfinder_updated_at_trigger
  BEFORE UPDATE ON "PathfindersTable"
  FOR EACH ROW
  EXECUTE FUNCTION update_pathfinder_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pathfinders_type ON "PathfindersTable"("Type");
CREATE INDEX IF NOT EXISTS idx_pathfinders_active ON "PathfindersTable"("IsActive");
CREATE INDEX IF NOT EXISTS idx_pathfinders_registration_year ON "PathfindersTable"("RegistrationYear");

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

DROP TRIGGER IF EXISTS campaign_pk_trigger ON "CampaignsTable";
CREATE TRIGGER campaign_pk_trigger
  BEFORE INSERT ON "CampaignsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_campaign_pk();

-- ============================================
-- 4. CREATE PRODUCTS TABLE (WITH COMBO SUPPORT)
-- ============================================

DROP TABLE IF EXISTS "ProductsTable" CASCADE;

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

DROP TRIGGER IF EXISTS validate_combo_items_trigger ON "ProductsTable";
CREATE TRIGGER validate_combo_items_trigger
  BEFORE INSERT OR UPDATE ON "ProductsTable"
  FOR EACH ROW
  EXECUTE FUNCTION validate_combo_items();

-- ============================================
-- 5. CREATE FEE TYPES TABLE
-- ============================================

DROP TABLE IF EXISTS "FeeTypesTable" CASCADE;

CREATE TABLE "FeeTypesTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "Name" TEXT NOT NULL,
  "Description" TEXT,
  "Amount" NUMERIC(10,2) NOT NULL CHECK ("Amount" >= 0),
  "FeeCategory" TEXT NOT NULL CHECK ("FeeCategory" IN ('membership', 'monthly', 'event', 'equipment', 'other')),
  "RecurrenceType" TEXT CHECK ("RecurrenceType" IN ('one-time', 'monthly', 'annual')),
  "AppliesTo" TEXT[] DEFAULT ARRAY['desbravador', 'staff', 'directors'],
  "DueDate" DATE,
  "IsActive" BOOLEAN DEFAULT true,
  "Year" INTEGER,
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "UpdatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Function to generate FeeType PK/SK
CREATE OR REPLACE FUNCTION generate_fee_type_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'FEETYPE#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS fee_type_pk_trigger ON "FeeTypesTable";
CREATE TRIGGER fee_type_pk_trigger
  BEFORE INSERT ON "FeeTypesTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_fee_type_pk();

-- Trigger for UpdatedAt
CREATE OR REPLACE FUNCTION update_fee_type_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."UpdatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS fee_type_updated_at_trigger ON "FeeTypesTable";
CREATE TRIGGER fee_type_updated_at_trigger
  BEFORE UPDATE ON "FeeTypesTable"
  FOR EACH ROW
  EXECUTE FUNCTION update_fee_type_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_fee_types_category ON "FeeTypesTable"("FeeCategory");
CREATE INDEX IF NOT EXISTS idx_fee_types_active ON "FeeTypesTable"("IsActive");
CREATE INDEX IF NOT EXISTS idx_fee_types_year ON "FeeTypesTable"("Year");
CREATE INDEX IF NOT EXISTS idx_fee_types_due_date ON "FeeTypesTable"("DueDate");

-- ============================================
-- 6. CREATE PATHFINDER FEES TABLE
-- ============================================

DROP TABLE IF EXISTS "PathfinderFeesTable" CASCADE;

CREATE TABLE "PathfinderFeesTable" (
  "PK" TEXT PRIMARY KEY,
  "SK" TEXT NOT NULL,
  "PathfinderId" TEXT NOT NULL REFERENCES "PathfindersTable"("PK") ON DELETE CASCADE,
  "FeeTypeId" TEXT NOT NULL REFERENCES "FeeTypesTable"("PK") ON DELETE CASCADE,
  "Amount" NUMERIC(10,2) NOT NULL CHECK ("Amount" >= 0),
  "DueDate" DATE NOT NULL,
  "Status" TEXT DEFAULT 'pending' CHECK ("Status" IN ('pending', 'partial', 'paid', 'overdue', 'waived')),
  "AmountPaid" NUMERIC(10,2) DEFAULT 0 CHECK ("AmountPaid" >= 0),
  "AmountRemaining" NUMERIC(10,2) NOT NULL CHECK ("AmountRemaining" >= 0),
  "Notes" TEXT,
  "AssignedAt" TIMESTAMPTZ DEFAULT NOW(),
  "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE ("PathfinderId", "FeeTypeId")
);

-- Function to generate PathfinderFee PK/SK and calculate amounts
CREATE OR REPLACE FUNCTION generate_pathfinder_fee_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'PATHFINDERFEE#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;

  -- Auto-calculate AmountRemaining
  NEW."AmountRemaining" := NEW."Amount" - COALESCE(NEW."AmountPaid", 0);

  -- Auto-update status based on payment
  IF NEW."AmountPaid" >= NEW."Amount" THEN
    NEW."Status" := 'paid';
  ELSIF NEW."AmountPaid" > 0 THEN
    NEW."Status" := 'partial';
  ELSIF NEW."DueDate" < CURRENT_DATE AND NEW."Status" = 'pending' THEN
    NEW."Status" := 'overdue';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pathfinder_fee_pk_trigger ON "PathfinderFeesTable";
CREATE TRIGGER pathfinder_fee_pk_trigger
  BEFORE INSERT ON "PathfinderFeesTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_pathfinder_fee_pk();

-- Trigger to update status/remaining on update
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

DROP TRIGGER IF EXISTS pathfinder_fee_status_trigger ON "PathfinderFeesTable";
CREATE TRIGGER pathfinder_fee_status_trigger
  BEFORE UPDATE ON "PathfinderFeesTable"
  FOR EACH ROW
  EXECUTE FUNCTION update_pathfinder_fee_status();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pathfinder_fees_pathfinder ON "PathfinderFeesTable"("PathfinderId");
CREATE INDEX IF NOT EXISTS idx_pathfinder_fees_type ON "PathfinderFeesTable"("FeeTypeId");
CREATE INDEX IF NOT EXISTS idx_pathfinder_fees_status ON "PathfinderFeesTable"("Status");
CREATE INDEX IF NOT EXISTS idx_pathfinder_fees_due_date ON "PathfinderFeesTable"("DueDate");

-- ============================================
-- 7. CREATE PAYMENTS TABLE
-- ============================================

DROP TABLE IF EXISTS "PaymentsTable" CASCADE;

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

-- Function to generate Payment PK/SK
CREATE OR REPLACE FUNCTION generate_payment_pk()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PK" IS NULL OR NEW."PK" = '' THEN
    NEW."PK" := 'PAYMENT#' || uuid_generate_v4();
  END IF;
  IF NEW."SK" IS NULL OR NEW."SK" = '' THEN
    NEW."SK" := NEW."PK";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_pk_trigger ON "PaymentsTable";
CREATE TRIGGER payment_pk_trigger
  BEFORE INSERT ON "PaymentsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_payment_pk();

-- CRITICAL TRIGGER: Update PathfinderFee AmountPaid when payment is added
CREATE OR REPLACE FUNCTION update_pathfinder_fee_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE "PathfinderFeesTable"
  SET "AmountPaid" = "AmountPaid" + NEW."Amount"
  WHERE "PK" = NEW."PathfinderFeeId";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_update_fee_trigger ON "PaymentsTable";
CREATE TRIGGER payment_update_fee_trigger
  AFTER INSERT ON "PaymentsTable"
  FOR EACH ROW
  EXECUTE FUNCTION update_pathfinder_fee_on_payment();

-- CRITICAL TRIGGER: Revert PathfinderFee AmountPaid when payment is deleted
CREATE OR REPLACE FUNCTION revert_pathfinder_fee_on_payment_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE "PathfinderFeesTable"
  SET "AmountPaid" = "AmountPaid" - OLD."Amount"
  WHERE "PK" = OLD."PathfinderFeeId";
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_delete_fee_trigger ON "PaymentsTable";
CREATE TRIGGER payment_delete_fee_trigger
  AFTER DELETE ON "PaymentsTable"
  FOR EACH ROW
  EXECUTE FUNCTION revert_pathfinder_fee_on_payment_delete();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_payments_pathfinder ON "PaymentsTable"("PathfinderId");
CREATE INDEX IF NOT EXISTS idx_payments_fee ON "PaymentsTable"("PathfinderFeeId");
CREATE INDEX IF NOT EXISTS idx_payments_date ON "PaymentsTable"("PaymentDate");
CREATE INDEX IF NOT EXISTS idx_payments_method ON "PaymentsTable"("PaymentMethod");

-- ============================================
-- 8. CREATE ORDERS TABLE (WITH CAMPAIGN SUPPORT)
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
CREATE INDEX IF NOT EXISTS idx_orders_campaign ON "OrdersTable"("CampaignId");

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

DROP TRIGGER IF EXISTS order_pk_trigger ON "OrdersTable";
CREATE TRIGGER order_pk_trigger
  BEFORE INSERT ON "OrdersTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_order_pk();

-- ============================================
-- 9. CREATE ORDER ITEMS TABLE
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

DROP TRIGGER IF EXISTS order_item_pk_trigger ON "OrderItemsTable";
CREATE TRIGGER order_item_pk_trigger
  BEFORE INSERT ON "OrderItemsTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_order_item_pk();

-- ============================================
-- 10. CREATE PRICE HISTORY TABLE
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

DROP TRIGGER IF EXISTS price_history_pk_trigger ON "PriceHistoryTable";
CREATE TRIGGER price_history_pk_trigger
  BEFORE INSERT ON "PriceHistoryTable"
  FOR EACH ROW
  EXECUTE FUNCTION generate_price_history_pk();

-- ============================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE "PathfindersTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "CampaignsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ProductsTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "FeeTypesTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PathfinderFeesTable" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PaymentsTable" ENABLE ROW LEVEL SECURITY;
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

-- FeeTypesTable Policies
DROP POLICY IF EXISTS "fee_types_select" ON "FeeTypesTable";
CREATE POLICY "fee_types_select" ON "FeeTypesTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "fee_types_insert" ON "FeeTypesTable";
CREATE POLICY "fee_types_insert" ON "FeeTypesTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "fee_types_update" ON "FeeTypesTable";
CREATE POLICY "fee_types_update" ON "FeeTypesTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "fee_types_delete" ON "FeeTypesTable";
CREATE POLICY "fee_types_delete" ON "FeeTypesTable"
  FOR DELETE TO authenticated USING (true);

-- PathfinderFeesTable Policies
DROP POLICY IF EXISTS "pathfinder_fees_select" ON "PathfinderFeesTable";
CREATE POLICY "pathfinder_fees_select" ON "PathfinderFeesTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "pathfinder_fees_insert" ON "PathfinderFeesTable";
CREATE POLICY "pathfinder_fees_insert" ON "PathfinderFeesTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "pathfinder_fees_update" ON "PathfinderFeesTable";
CREATE POLICY "pathfinder_fees_update" ON "PathfinderFeesTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "pathfinder_fees_delete" ON "PathfinderFeesTable";
CREATE POLICY "pathfinder_fees_delete" ON "PathfinderFeesTable"
  FOR DELETE TO authenticated USING (true);

-- PaymentsTable Policies
DROP POLICY IF EXISTS "payments_select" ON "PaymentsTable";
CREATE POLICY "payments_select" ON "PaymentsTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "payments_insert" ON "PaymentsTable";
CREATE POLICY "payments_insert" ON "PaymentsTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "payments_update" ON "PaymentsTable";
CREATE POLICY "payments_update" ON "PaymentsTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "payments_delete" ON "PaymentsTable";
CREATE POLICY "payments_delete" ON "PaymentsTable"
  FOR DELETE TO authenticated USING (true);

-- OrdersTable Policies
DROP POLICY IF EXISTS "orders_select" ON "OrdersTable";
CREATE POLICY "orders_select" ON "OrdersTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "orders_insert" ON "OrdersTable";
CREATE POLICY "orders_insert" ON "OrdersTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "orders_update" ON "OrdersTable";
CREATE POLICY "orders_update" ON "OrdersTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "orders_delete" ON "OrdersTable";
CREATE POLICY "orders_delete" ON "OrdersTable"
  FOR DELETE TO authenticated USING (true);

-- OrderItemsTable Policies
DROP POLICY IF EXISTS "order_items_select" ON "OrderItemsTable";
CREATE POLICY "order_items_select" ON "OrderItemsTable"
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "order_items_insert" ON "OrderItemsTable";
CREATE POLICY "order_items_insert" ON "OrderItemsTable"
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "order_items_update" ON "OrderItemsTable";
CREATE POLICY "order_items_update" ON "OrderItemsTable"
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "order_items_delete" ON "OrderItemsTable";
CREATE POLICY "order_items_delete" ON "OrderItemsTable"
  FOR DELETE TO authenticated USING (true);

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
-- 12. HELPER FUNCTIONS
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

-- Function to get document completion status for a pathfinder
CREATE OR REPLACE FUNCTION get_document_completion(pathfinder_type TEXT, documents JSONB)
RETURNS TABLE (
  total_required INTEGER,
  total_received INTEGER,
  completion_percentage NUMERIC
) AS $$
DECLARE
  required_docs TEXT[];
  received_count INTEGER := 0;
  doc_key TEXT;
BEGIN
  CASE pathfinder_type
    WHEN 'desbravador' THEN
      required_docs := ARRAY['id_cpf', 'sus_card', 'proof_residence', 'parent_id_cpf', 'vaccination_card'];
    WHEN 'staff' THEN
      required_docs := ARRAY['id_cpf', 'sus_card', 'proof_residence', 'criminal_background'];
    WHEN 'directors' THEN
      required_docs := ARRAY['id_cpf', 'sus_card', 'proof_residence', 'criminal_background'];
    ELSE
      required_docs := ARRAY['id_cpf', 'sus_card', 'proof_residence'];
  END CASE;

  FOREACH doc_key IN ARRAY required_docs LOOP
    IF (documents->doc_key->>'status') = 'received' THEN
      received_count := received_count + 1;
    END IF;
  END LOOP;

  RETURN QUERY SELECT
    array_length(required_docs, 1) AS total_required,
    received_count AS total_received,
    CASE
      WHEN array_length(required_docs, 1) = 0 THEN 0
      ELSE ROUND((received_count::NUMERIC / array_length(required_docs, 1)::NUMERIC) * 100, 2)
    END AS completion_percentage;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-mark overdue fees
CREATE OR REPLACE FUNCTION mark_overdue_fees()
RETURNS void AS $$
BEGIN
  UPDATE "PathfinderFeesTable"
  SET "Status" = 'overdue'
  WHERE "Status" IN ('pending', 'partial')
    AND "DueDate" < CURRENT_DATE
    AND "AmountRemaining" > 0;
END;
$$ LANGUAGE plpgsql;

-- Create view for financial summary by pathfinder
CREATE OR REPLACE VIEW pathfinder_financial_summary AS
SELECT
  pf."PK" AS pathfinder_id,
  pf."Name" AS pathfinder_name,
  pf."Type" AS pathfinder_type,
  COUNT(DISTINCT fees."PK") AS total_fees_assigned,
  COALESCE(SUM(fees."Amount"), 0) AS total_amount_owed,
  COALESCE(SUM(fees."AmountPaid"), 0) AS total_amount_paid,
  COALESCE(SUM(fees."AmountRemaining"), 0) AS total_amount_remaining,
  COUNT(CASE WHEN fees."Status" = 'overdue' THEN 1 END) AS overdue_fees_count,
  COUNT(CASE WHEN fees."Status" = 'paid' THEN 1 END) AS paid_fees_count,
  COUNT(DISTINCT payments."PK") AS total_payments_made
FROM "PathfindersTable" pf
LEFT JOIN "PathfinderFeesTable" fees ON fees."PathfinderId" = pf."PK"
LEFT JOIN "PaymentsTable" payments ON payments."PathfinderId" = pf."PK"
GROUP BY pf."PK", pf."Name", pf."Type";

-- ============================================
-- 13. CREATE DEFAULT CAMPAIGN
-- ============================================

INSERT INTO "CampaignsTable" ("Name", "StartDate", "EndDate", "Status", "Description")
VALUES (
  'Campanha Inicial',
  '2024-01-01',
  '2025-12-31',
  'active',
  'Campanha criada automaticamente para pedidos existentes'
)
ON CONFLICT DO NOTHING;

UPDATE "OrdersTable"
SET "CampaignId" = (SELECT "PK" FROM "CampaignsTable" WHERE "Name" = 'Campanha Inicial')
WHERE "CampaignId" IS NULL;

-- ============================================
-- DONE!
-- ============================================
-- All tables created with auto-generating PK/SK
-- Pattern: PATHFINDER#<uuid>
--         CAMPAIGN#<uuid>
--         PRODUCT#<uuid>
--         FEETYPE#<uuid>
--         PATHFINDERFEE#<uuid>
--         PAYMENT#<uuid>
--         ORDER#<uuid>
--         ORDERITEM#<uuid>
--         PRICEHISTORY#<uuid>
--
-- Features included:
-- ✅ Pathfinders management with types and documents
-- ✅ Campaign tracking (monthly/periodic fundraisers)
-- ✅ Products with flavors and combo support
-- ✅ Financial tracking (fees, payments, installments)
-- ✅ Document management (checkbox status tracking)
-- ✅ Orders with campaign assignment
-- ✅ Order items tracking
-- ✅ Price history
-- ✅ Row Level Security (RLS)
-- ✅ Helper functions
-- ✅ Payment triggers (auto-update fee status)
-- ============================================
