# Admin — Database Documentation (M7)

**Module:** Admin / Backend Management
**Database:** PostgreSQL

## Purpose

Provides access to the existing centralized database records for administrative monitoring and management. The Admin module also stores records of administrative actions.

> **Important:** The tables used by Admin are the same centralized tables used by the other modules. They are not separate Admin copies and do not increase the total table count. Only `admin_activity_logs` is new.

## 8.1 Admin-Specific Table

### Table 26: `admin_activity_logs`

**Description:** Records important actions performed by administrators.

| Column | Data Type | Constraint |
|---|---|---|
| `log_id` | UUID | PK |
| `admin_id` | UUID | FK → `users.user_id`, NOT NULL |
| `action` | VARCHAR(100) | NOT NULL |
| `target_table` | VARCHAR(100) | NULL |
| `target_id` | UUID | NULL |
| `details` | JSONB | NULL |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() |

**Relationships:**

- `admin_activity_logs.admin_id` → `users.user_id`
- One administrator may have multiple activity log records.

**Implementation notes:**

- `admin_id` uses `ON DELETE RESTRICT` so logs are never lost when an account is removed. Suspend accounts instead of deleting them.
- The table is append-only: triggers block `UPDATE`, `DELETE` and `TRUNCATE`.
- A trigger checks that `admin_id` belongs to a user with `role = 'admin'`.
- Suggested `action` values: `APPROVE_USER`, `REJECT_USER`, `SUSPEND_USER`, `REACTIVATE_USER`, `APPROVE_MERCHANT`, `REJECT_MERCHANT`, `SUSPEND_MERCHANT`, `APPROVE_RIDER`, `REJECT_RIDER`, `MANAGE_BARANGAY`, `MANAGE_CATEGORY`, `MODERATE_REVIEW`, `RESOLVE_REPORT`, `SEND_NOTIFICATION`, `VIEW_PRESCRIPTION`, `VIEW_RESIDENT_PROFILE`, `VIEW_RIDER_LOCATION`.

## Existing Tables Used by Admin

| Existing Table | Description | Note |
|---|---|---|
| `users` | Allows administrators to view and manage all platform accounts. | Admin operations: view all accounts; approve or reject eligible accounts; suspend or reactivate accounts; filter accounts by role and status; review account registration information. |
| `resident_profiles` | Allows authorized administrators to review resident profile information. | View resident information when necessary for authorized account management or support. |
| `barangays` | Allows administrators to manage the supported barangay list. | |
| `addresses` | Allows administrators to view resident and pharmacy addresses when authorized. | |
| `merchant_profiles` | Allows administrators to approve, reject, suspend, and monitor participating pharmacies. | |
| `merchant_hours` | Allows administrators to view pharmacy operating schedules. | |
| `product_categories` | Allows administrators to manage product categories. | |
| `products` | Allows administrators to monitor pharmacy product listings. | |
| `inventory` | Allows administrators to monitor product stock and low-stock conditions. | |
| `carts` | Allows authorized administrators to inspect active cart records when investigating customer issues. | |
| `cart_items` | Allows authorized administrators to inspect the contents of active carts. | |
| `orders` | Allows administrators to monitor all platform orders. | |
| `order_items` | Allows administrators to inspect the items and historical prices included in orders. | |
| `order_status_history` | Allows administrators to inspect the complete history of order status changes. | |
| `prescriptions` | Allows authorized administrators to monitor prescription submissions and investigate prescription-related issues. | |
| `payments` | Allows administrators to monitor COD payments and collection discrepancies. | |
| `rider_profiles` | Allows administrators to review rider information, vehicle details, and approval status. | |
| `deliveries` | Allows administrators to monitor rider assignments and delivery progress. | |
| `delivery_offers` | Allows administrators to review delivery offers and rider responses. | Recommended constraint: `UNIQUE (delivery_id, rider_id)`. |
| `delivery_status_history` | Allows administrators to review delivery status changes. | |
| `rider_locations` | Allows authorized administrators to monitor rider locations during active deliveries. | |
| `rider_earnings` | Allows administrators to monitor rider earnings and payout status. | |
| `rider_ratings` | Allows administrators to monitor rider ratings and comments. | |
| `medicine_searches` | Allows administrators to review medicine search activity for basic platform analytics. | |
| `pharmacy_reviews` | Allows administrators to monitor and moderate pharmacy reviews. | |
| `problem_reports` | Allows administrators to review customer complaints and resolve platform issues. | |
| `emergency_alerts` | Allows administrators to view and monitor submitted emergency alert records. | |
| `notifications` | Allows administrators to send and monitor notifications for authorized platform activities. | |

## Admin Instructions

- Dashboard totals must be calculated from the actual records.
- Do not create separate tables just to store dashboard totals. (Implemented as the view `v_admin_dashboard`.)
- Every important administrative modification must be recorded in `admin_activity_logs`.
- Admin access must be checked by the PHP backend.
- Sensitive resident information, prescription files, and rider location records must have restricted access.

## Database Files

| File | Purpose |
|---|---|
| `m7_existing_tables.sql` | Creates the existing centralized tables and the `v_admin_dashboard` view |
| `m7_admin_activity_logs.sql` | Creates Table 26, its indexes, triggers and `log_admin_action()` |
| `admin_seed.sql` | Seeds admin accounts, barangays, product categories, test accounts and sample logs |

**Run order:** `m7_existing_tables.sql` → `m7_admin_activity_logs.sql` → `admin_seed.sql`

## Seed Data Summary

- 2 admin accounts (`admin@example.com`, `admin2@example.com`), default password `ChangeMe123!`. **Change it before deployment.**
- 3 placeholder barangays (replace with the real supported list).
- 6 product categories.
- Test accounts: 1 resident, 1 pending pharmacy, 1 pending rider. **Remove before production.**
- 2 sample entries in `admin_activity_logs`.

## Example Queries

```sql
-- Dashboard totals (computed from real records)
SELECT * FROM v_admin_dashboard;

-- Pending pharmacies awaiting approval
SELECT merchant_id, pharmacy_name, license_number, created_at
FROM merchant_profiles
WHERE status = 'pending'
ORDER BY created_at;

-- Log an admin action (called from PHP after each admin change)
SELECT log_admin_action(
    '<admin_user_id>', 'APPROVE_MERCHANT', 'merchant_profiles', '<merchant_id>',
    '{"old_status":"pending","new_status":"approved"}'::jsonb
);

-- Recent admin activity
SELECT l.created_at, u.email AS admin, l.action, l.target_table, l.target_id
FROM admin_activity_logs l
JOIN users u ON u.user_id = l.admin_id
ORDER BY l.created_at DESC
LIMIT 50;
```

## Assumptions

The columns of the existing tables were not in the provided specification, so `m7_existing_tables.sql` uses assumed columns based on each table's description. Adjust them to match the final design.
