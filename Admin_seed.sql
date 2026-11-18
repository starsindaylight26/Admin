CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- for bcrypt password hashing

-- ------------------------------------------------------------
-- 1. Admin accounts
-- Default password: ChangeMe123!   (CHANGE THIS after first login)
-- Hash is bcrypt, which PHP's password_verify() can check.
-- ------------------------------------------------------------
INSERT INTO users (user_id, email, phone, password_hash, role, status)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'admin@example.com',  '09000000001',
   crypt('ChangeMe123!', gen_salt('bf', 10)), 'admin', 'active'),
  ('a0000000-0000-0000-0000-000000000002', 'admin2@example.com', '09000000002',
   crypt('ChangeMe123!', gen_salt('bf', 10)), 'admin', 'active')
ON CONFLICT (user_id) DO NOTHING;

-- ------------------------------------------------------------
-- 2. Supported barangay list (managed by admin)
-- Placeholder names: replace with your real supported barangays.
-- ------------------------------------------------------------
INSERT INTO barangays (barangay_id, name, city, province, is_active)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'Barangay Sample 1', 'Sample City', 'Sample Province', TRUE),
  ('b0000000-0000-0000-0000-000000000002', 'Barangay Sample 2', 'Sample City', 'Sample Province', TRUE),
  ('b0000000-0000-0000-0000-000000000003', 'Barangay Sample 3', 'Sample City', 'Sample Province', TRUE)
ON CONFLICT (name, city) DO NOTHING;

-- ------------------------------------------------------------
-- 3. Product categories (managed by admin)
-- ------------------------------------------------------------
INSERT INTO product_categories (category_id, name, description, is_active)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Pain Relief & Fever',    'Analgesics and antipyretics',          TRUE),
  ('c0000000-0000-0000-0000-000000000002', 'Cough, Cold & Flu',      'Relief for cough, colds and flu',      TRUE),
  ('c0000000-0000-0000-0000-000000000003', 'Vitamins & Supplements', 'Vitamins, minerals and supplements',   TRUE),
  ('c0000000-0000-0000-0000-000000000004', 'Maintenance Medicines',  'Long-term medication (Rx may apply)',  TRUE),
  ('c0000000-0000-0000-0000-000000000005', 'First Aid',              'Wound care and first aid supplies',    TRUE),
  ('c0000000-0000-0000-0000-000000000006', 'Personal Care',          'Hygiene and personal care products',   TRUE)
ON CONFLICT (name) DO NOTHING;

-- ------------------------------------------------------------
-- 4. Sample accounts for testing admin approval flows
-- (pending resident, merchant and rider; delete before production)
-- ------------------------------------------------------------
INSERT INTO users (user_id, email, phone, password_hash, role, status)
VALUES
  ('d0000000-0000-0000-0000-000000000001', 'resident.test@example.com', '09100000001',
   crypt('ChangeMe123!', gen_salt('bf', 10)), 'resident', 'active'),
  ('d0000000-0000-0000-0000-000000000002', 'pharmacy.test@example.com', '09100000002',
   crypt('ChangeMe123!', gen_salt('bf', 10)), 'merchant', 'pending'),
  ('d0000000-0000-0000-0000-000000000003', 'rider.test@example.com',    '09100000003',
   crypt('ChangeMe123!', gen_salt('bf', 10)), 'rider',    'pending')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO resident_profiles (resident_id, user_id, first_name, last_name, contact_number)
VALUES
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
   'Test', 'Resident', '09100000001')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO merchant_profiles (merchant_id, user_id, pharmacy_name, license_number, status)
VALUES
  ('f0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002',
   'Test Pharmacy', 'LIC-TEST-0001', 'pending')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO rider_profiles (rider_id, user_id, vehicle_type, plate_number, license_number, approval_status)
VALUES
  ('f1000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000003',
   'Motorcycle', 'ABC 1234', 'DL-TEST-0001', 'pending')
ON CONFLICT (user_id) DO NOTHING;

-- ------------------------------------------------------------
-- 5. Sample admin activity log entries
-- ------------------------------------------------------------
INSERT INTO admin_activity_logs (log_id, admin_id, action, target_table, target_id, details)
VALUES
  ('90000000-0000-0000-0000-000000000001',
   'a0000000-0000-0000-0000-000000000001', 'SEED_ADMIN_ACCOUNT', 'users',
   'a0000000-0000-0000-0000-000000000001',
   '{"note": "Initial admin account created by seed script"}'::jsonb),
  ('90000000-0000-0000-0000-000000000002',
   'a0000000-0000-0000-0000-000000000001', 'MANAGE_CATEGORY', 'product_categories',
   'c0000000-0000-0000-0000-000000000001',
   '{"note": "Initial product categories created by seed script"}'::jsonb)
ON CONFLICT (log_id) DO NOTHING;
