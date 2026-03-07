-- ============================================
-- ROLLBACK SCRIPT - FINANCIAL & DOCUMENT TRACKING
-- ============================================
-- This script undoes the financial tracking migration
-- Run this in Supabase SQL Editor to remove all changes
-- ============================================

-- ============================================
-- 1. DROP NEW TABLES
-- ============================================

DROP TABLE IF EXISTS "PaymentsTable" CASCADE;
DROP TABLE IF EXISTS "PathfinderFeesTable" CASCADE;
DROP TABLE IF EXISTS "FeeTypesTable" CASCADE;

-- ============================================
-- 2. DROP NEW FUNCTIONS
-- ============================================

DROP FUNCTION IF EXISTS update_pathfinder_fee_on_payment() CASCADE;
DROP FUNCTION IF EXISTS revert_pathfinder_fee_on_payment_delete() CASCADE;
DROP FUNCTION IF EXISTS generate_payment_pk() CASCADE;
DROP FUNCTION IF EXISTS update_pathfinder_fee_status() CASCADE;
DROP FUNCTION IF EXISTS generate_pathfinder_fee_pk() CASCADE;
DROP FUNCTION IF EXISTS update_fee_type_updated_at() CASCADE;
DROP FUNCTION IF EXISTS generate_fee_type_pk() CASCADE;
DROP FUNCTION IF EXISTS update_pathfinder_updated_at() CASCADE;
DROP FUNCTION IF EXISTS get_document_completion(TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS mark_overdue_fees() CASCADE;

-- ============================================
-- 3. DROP VIEW
-- ============================================

DROP VIEW IF EXISTS pathfinder_financial_summary CASCADE;

-- ============================================
-- 4. REMOVE COLUMNS FROM PATHFINDERSTABLE
-- ============================================

ALTER TABLE "PathfindersTable"
DROP COLUMN IF EXISTS "Type",
DROP COLUMN IF EXISTS "Email",
DROP COLUMN IF EXISTS "Phone",
DROP COLUMN IF EXISTS "ParentName",
DROP COLUMN IF EXISTS "ParentEmail",
DROP COLUMN IF EXISTS "ParentPhone",
DROP COLUMN IF EXISTS "BirthDate",
DROP COLUMN IF EXISTS "Address",
DROP COLUMN IF EXISTS "Notes",
DROP COLUMN IF EXISTS "IsActive",
DROP COLUMN IF EXISTS "RegistrationYear",
DROP COLUMN IF EXISTS "Documents",
DROP COLUMN IF EXISTS "UpdatedAt";

-- ============================================
-- 5. DROP INDEXES
-- ============================================

DROP INDEX IF EXISTS idx_pathfinders_type;
DROP INDEX IF EXISTS idx_pathfinders_active;
DROP INDEX IF EXISTS idx_pathfinders_registration_year;

-- ============================================
-- ROLLBACK COMPLETE!
-- ============================================
-- Your database is now back to its original state
-- Run the corrected schema file to apply changes properly
-- ============================================
