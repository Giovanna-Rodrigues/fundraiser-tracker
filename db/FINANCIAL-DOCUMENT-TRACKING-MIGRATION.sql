-- ============================================
-- FINANCIAL & DOCUMENT TRACKING MIGRATION
-- ============================================
-- This migration adds financial tracking and document management
-- features to the fundraiser tracker system.
--
-- Features added:
-- ✅ Extended PathfindersTable with Type, Documents, contact info
-- ✅ FeeTypesTable for defining membership/event/equipment fees
-- ✅ PathfinderFeesTable for fee assignments with payment tracking
-- ✅ PaymentsTable for recording payments with auto-update triggers
-- ✅ Document status tracking via JSONB
-- ✅ Automatic status updates (pending → partial → paid → overdue)
-- ============================================

-- ============================================
-- 1. EXTEND PATHFINDERS TABLE
-- ============================================

-- Add new columns to PathfindersTable
ALTER TABLE "PathfindersTable"
ADD COLUMN IF NOT EXISTS "Type" TEXT DEFAULT 'desbravador' CHECK ("Type" IN ('desbravador', 'staff', 'directors')),
ADD COLUMN IF NOT EXISTS "Email" TEXT,
ADD COLUMN IF NOT EXISTS "Phone" TEXT,
ADD COLUMN IF NOT EXISTS "ParentName" TEXT,
ADD COLUMN IF NOT EXISTS "ParentEmail" TEXT,
ADD COLUMN IF NOT EXISTS "ParentPhone" TEXT,
ADD COLUMN IF NOT EXISTS "BirthDate" DATE,
ADD COLUMN IF NOT EXISTS "Address" TEXT,
ADD COLUMN IF NOT EXISTS "Notes" TEXT,
ADD COLUMN IF NOT EXISTS "IsActive" BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS "RegistrationYear" INTEGER,
ADD COLUMN IF NOT EXISTS "Documents" JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS "UpdatedAt" TIMESTAMPTZ DEFAULT NOW();

-- Create indexes for filtering
CREATE INDEX IF NOT EXISTS idx_pathfinders_type ON "PathfindersTable"("Type");
CREATE INDEX IF NOT EXISTS idx_pathfinders_active ON "PathfindersTable"("IsActive");
CREATE INDEX IF NOT EXISTS idx_pathfinders_registration_year ON "PathfindersTable"("RegistrationYear");

-- Create trigger to auto-update UpdatedAt timestamp
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

-- ============================================
-- 2. CREATE FEE TYPES TABLE
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

-- Enable RLS
ALTER TABLE "FeeTypesTable" ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- 3. CREATE PATHFINDER FEES TABLE
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

-- Enable RLS
ALTER TABLE "PathfinderFeesTable" ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- 4. CREATE PAYMENTS TABLE
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
  -- Update the PathfinderFee AmountPaid
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

-- Enable RLS
ALTER TABLE "PaymentsTable" ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

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
  -- Define required documents based on type
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

  -- Count received documents
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

-- Function to auto-mark overdue fees (can be called manually or via scheduled job)
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
-- 6. INITIALIZE EXISTING PATHFINDERS
-- ============================================

-- Set default Type for existing pathfinders (if any)
UPDATE "PathfindersTable"
SET "Type" = 'desbravador',
    "IsActive" = true,
    "RegistrationYear" = EXTRACT(YEAR FROM "CreatedAt")::INTEGER,
    "Documents" = '{}'::jsonb
WHERE "Type" IS NULL;

-- ============================================
-- 7. SAMPLE DATA (OPTIONAL - COMMENT OUT IF NOT NEEDED)
-- ============================================

-- Uncomment below to insert sample fee types for testing

-- -- Annual Membership Fee
-- INSERT INTO "FeeTypesTable" ("Name", "Description", "Amount", "FeeCategory", "RecurrenceType", "AppliesTo", "IsActive", "Year")
-- VALUES (
--   'Anuidade 2026',
--   'Taxa de anuidade do clube para o ano de 2026',
--   150.00,
--   'membership',
--   'annual',
--   ARRAY['desbravador', 'staff', 'directors'],
--   true,
--   2026
-- );

-- -- DSA Campuri Event Fee
-- INSERT INTO "FeeTypesTable" ("Name", "Description", "Amount", "FeeCategory", "RecurrenceType", "AppliesTo", "DueDate", "IsActive", "Year")
-- VALUES (
--   'DSA Campuri 2026',
--   'Taxa de inscrição para o Campuri DSA - Prazo: 30/04/2026',
--   300.00,
--   'event',
--   'one-time',
--   ARRAY['desbravador'],
--   '2026-04-30',
--   true,
--   2026
-- );

-- -- Monthly Dues
-- INSERT INTO "FeeTypesTable" ("Name", "Description", "Amount", "FeeCategory", "RecurrenceType", "AppliesTo", "IsActive", "Year")
-- VALUES (
--   'Mensalidade Fevereiro 2026',
--   'Mensalidade referente ao mês de fevereiro de 2026',
--   50.00,
--   'monthly',
--   'monthly',
--   ARRAY['desbravador', 'staff', 'directors'],
--   true,
--   2026
-- );

-- -- Uniform/Equipment Purchase
-- INSERT INTO "FeeTypesTable" ("Name", "Description", "Amount", "FeeCategory", "RecurrenceType", "AppliesTo", "IsActive", "Year")
-- VALUES (
--   'Kit Uniforme Completo',
--   'Uniforme oficial do clube (camisa, calça, lenço, boina)',
--   200.00,
--   'equipment',
--   'one-time',
--   ARRAY['desbravador', 'staff', 'directors'],
--   true,
--   2026
-- );

-- ============================================
-- MIGRATION COMPLETE!
-- ============================================

-- You can verify the migration by running:
-- SELECT * FROM "FeeTypesTable";
-- SELECT * FROM "PathfinderFeesTable";
-- SELECT * FROM "PaymentsTable";
-- SELECT * FROM pathfinder_financial_summary;

-- To test the payment trigger:
-- 1. Create a fee type
-- 2. Assign it to a pathfinder (insert into PathfinderFeesTable)
-- 3. Add a payment (insert into PaymentsTable)
-- 4. Check that PathfinderFee.AmountPaid was auto-updated
-- 5. Verify PathfinderFee.Status changed from 'pending' to 'partial' or 'paid'

-- ============================================
-- NOTES:
-- ============================================
-- • All existing pathfinders are set to Type='desbravador' by default
-- • Documents field initialized as empty JSONB object for all pathfinders
-- • Fee assignment is manual (treasurer assigns fees to pathfinders)
-- • Payments automatically update fee status via triggers
-- • Overdue fees can be marked by calling mark_overdue_fees() function
-- • All tables have RLS enabled with authenticated access
-- • All tables follow ENTITY#uuid PK/SK pattern
-- ============================================
