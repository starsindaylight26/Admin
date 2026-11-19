# MedEx – Payment Module Database

**Platform:** Supabase (PostgreSQL)  
**Owned tables:** `payment_methods`, `payments`  
**Files:** `payment.sql` (schema), `payment_seed.sql` (sample data)

## Table: `payment_methods`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `method_id` | INT | PK, identity | Payment method ID |
| `label` | VARCHAR(50) | NOT NULL, UNIQUE | Payment method name, e.g. GCash, COD |

## Table: `payments`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `payment_id` | INT | PK, identity | Payment record ID |
| `order_id` | INT | NOT NULL, FK, UNIQUE | References `orders.order_id`; one payment record per order |
| `method_id` | INT | NOT NULL, FK | References `payment_methods.method_id` |
| `idempotency_key` | VARCHAR(64) | NOT NULL, UNIQUE | Prevents duplicate payment processing from retried requests |
| `amount` | NUMERIC(10,2) | NOT NULL | Payment amount; must match `orders.total_amount` |
| `amount_collected` | NUMERIC(10,2) | nullable | Cash amount collected by the rider for COD |
| `is_flagged` | BOOLEAN | NOT NULL, default FALSE | Indicates a COD collection discrepancy requiring Admin attention |
| `failure_reason` | TEXT | nullable | Reason a payment attempt failed |
| `status` | VARCHAR(20) | NOT NULL, default 'pending', CHECK | Payment status |
| `paid_at` | TIMESTAMPTZ | nullable | Time payment was confirmed |
| `created_at` | TIMESTAMPTZ | NOT NULL, default NOW() | Time the payment record was created |
| `gateway_reference` | VARCHAR(255) | nullable | Payment gateway reference, when applicable |

## Status values

`PENDING`, `PAID`, `COLLECTED`, `FAILED`.

- COD starts as `PENDING` and becomes `COLLECTED` only after the rider confirms cash collection.
- GCash becomes `PAID` only after the backend verifies the payment gateway webhook signature and payment result. A client-side success screen is not sufficient.
- A failed GCash payment may be retried using the same payment row (`FAILED` → `PENDING`).
- A failed GCash payment may be changed to COD, subject to the agreed one-payment-row-per-order implementation.
- Duplicate webhook deliveries must not change the payment more than once. Invalid webhook signatures must be rejected and logged.
- If the COD amount collected does not match the payment amount, set `is_flagged` and notify Admin.

## Database Connections

- `payments.order_id` → `orders.order_id` (Order module).
- `payments.method_id` → `payment_methods.method_id` (this module).
- Order status and payment status must be synchronized with the Order module.
- COD collection requires coordination with the Rider/Delivery module.
- Administrative review of flagged COD discrepancies requires coordination with the Admin/Backend module.

## Coordination

- **Order module:** Confirm `orders.order_id` is an `INTEGER` primary key and `orders.total_amount` is `NUMERIC(10,2)`. The Orders team's supplied MariaDB definition uses `INT(11)` and `DECIMAL(10,2)`; these correspond to PostgreSQL `INTEGER` and `NUMERIC(10,2)` respectively after conversion.
- **Shared database dependency:** `public.orders` must exist in the same Supabase PostgreSQL database before the foreign key in `payment.sql` can be created. If it does not exist, PostgreSQL reports `relation "public.orders" does not exist`. Create the Orders table first, then run the Payment schema.
- **Prescription orders:** Do not initiate GCash charging until the pharmacist has approved the prescription.
- **Rider/Delivery:** Confirm how COD collection is recorded and whether `paid_at` is also used as the COD collection timestamp. The current documented schema does not define a separate `collected_at` column.
- **Payment method availability:** The UI displays active payment methods, but the documented `payment_methods` schema does not define an `is_active` column. Confirm whether that column is required before adding it.
- **Receipt number:** The UI describes a unique receipt number, but the documented `payments` schema does not define a `receipt_number` column. Confirm whether `payment_id` is the receipt identifier or whether a separate column is required.
- **Retry / method change:** Because `payments.order_id` is unique, a retry or switch from GCash to COD must not create a second payment row. Confirm the backend's update behavior with the team.
- **Gateway:** Confirm whether GCash is processed through the PayMongo sandbox/integration or a simulated flow. The backend must own webhook signature verification and idempotent event handling.
- **Refunds:** Refund-record handling is not included here because the project documentation contains conflicting scope/UI references. Confirm with the module owner before adding refund tables or columns.

## Security (Row Level Security)

The Payment module documentation does not specify final Row Level Security (RLS) policies. Agree on access rules with the Backend/Admin and User module owners before enabling client access.

At minimum, payment gateway secrets and webhook signature verification must remain server-side. Do not store real payment credentials or other sensitive financial information in these tables. Do not assume that enabling RLS alone provides the required access rules; define and test explicit policies before exposing the tables to authenticated clients.

## How to Run

1. Supabase Dashboard → SQL Editor.
2. Confirm that the Orders module has already created `public.orders` in this same Supabase project.
3. Run `payment.sql`.
4. Run `payment_seed.sql`.

**Important:** The schema is a draft pending team confirmation of the coordination items above. Do not run it in the shared Supabase project until the Orders dependency and the pending design decisions have been reviewed.
