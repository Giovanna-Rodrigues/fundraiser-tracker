-- ============================================
-- ORDER UPDATES MIGRATION
-- ============================================
-- Adds 'not_picked_up' status to orders and makes
-- PaymentMethod nullable to support "pay later" orders.
-- Safe to run on existing data — additive changes only.
-- ============================================

-- 1. Add 'not_picked_up' to the Status CHECK constraint
ALTER TABLE "OrdersTable" DROP CONSTRAINT IF EXISTS orderstable_status_check;
ALTER TABLE "OrdersTable" ADD CONSTRAINT orderstable_status_check
  CHECK ("Status" IN ('pending', 'preparing', 'ready', 'delivered', 'not_picked_up'));

-- 2. Allow PaymentMethod to be NULL (pay later orders)
ALTER TABLE "OrdersTable" ALTER COLUMN "PaymentMethod" DROP NOT NULL;
ALTER TABLE "OrdersTable" DROP CONSTRAINT IF EXISTS orderstable_paymentmethod_check;
ALTER TABLE "OrdersTable" ADD CONSTRAINT orderstable_paymentmethod_check
  CHECK ("PaymentMethod" IS NULL OR "PaymentMethod" IN ('card', 'cash', 'pix-church', 'pix-qr'));

-- Verify changes
SELECT column_name, is_nullable, data_type
FROM information_schema.columns
WHERE table_name = 'OrdersTable'
  AND column_name IN ('Status', 'PaymentMethod');
