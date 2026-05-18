-- =====================================================================
-- MoMo SMS Analytics — CRUD & Analytical Test Queries
-- File: database/crud_operations.sql
-- Purpose: Validate all 5 tables (users, transaction_categories,
--          transactions, transaction_participants, system_logs) via
--          representative INSERT / SELECT / UPDATE / DELETE and
--          analytical queries.
-- Engine : MySQL 8.x  |  Run AFTER database_setup.sql is loaded.
-- =====================================================================

USE momo_sms;

-- ===== CREATE (INSERT) =====

-- Purpose: Insert a new MERCHANT user that will be the receiver in our
--          test transaction.  No phone number — merchants use NULL per schema.
INSERT INTO users (full_name, phone_number, user_type)
VALUES ('Rwanda Coffee House', NULL, 'MERCHANT');

-- Purpose: Insert a new Payment-to-Code-Holder transaction (category_id = 2)
--          that references the merchant we just created.
--          new_balance left NULL because it is not available in this test context.
INSERT INTO transactions
  (external_txn_id, category_id, amount, fee, new_balance, transaction_date, raw_message)
VALUES (
  'TX1006',
  2,                              -- Payment to Code Holder
  7500.00,
  75.00,
  NULL,
  '2024-05-13 10:00:00',
  'TxId: TX1006. Your payment of 7500 RWF to Rwanda Coffee House.'
);

-- Purpose: Link TX1006 to its sender (Samuel Carter) and receiver
--          (Rwanda Coffee House) through the junction table.
--          Subqueries make this portable — no hard-coded IDs.
INSERT INTO transaction_participants (transaction_id, user_id, role)
VALUES
  (
    (SELECT transaction_id FROM transactions  WHERE external_txn_id = 'TX1006'),
    (SELECT user_id         FROM users        WHERE full_name = 'Samuel Carter'),
    'SENDER'
  ),
  (
    (SELECT transaction_id FROM transactions  WHERE external_txn_id = 'TX1006'),
    (SELECT user_id         FROM users        WHERE full_name = 'Rwanda Coffee House'),
    'RECEIVER'
  );


-- ===== READ (SELECT) =====

-- Purpose: List every transaction in the "Payment to Code Holder" category,
--          newest first.  Confirms category FK join works.
SELECT
    t.transaction_id,
    t.external_txn_id,
    t.amount,
    t.fee,
    t.transaction_date
FROM transactions AS t
JOIN transaction_categories AS tc
  ON t.category_id = tc.category_id
WHERE tc.category_name = 'Payment to Code Holder'
ORDER BY t.transaction_date DESC;

-- Purpose: Spot-check high-value transactions (> 5000 RWF).
--          Shows range filtering on the DECIMAL amount column.
SELECT
    t.external_txn_id,
    tc.category_name,
    t.amount,
    t.transaction_date
FROM transactions AS t
JOIN transaction_categories AS tc
  ON t.category_id = tc.category_id
WHERE t.amount > 5000.00
ORDER BY t.amount DESC;

-- Purpose: Retrieve Samuel Carter's complete transaction history.
--          This is the primary proof that the M:N design works —
--          we navigate users -> transaction_participants -> transactions.
SELECT
    t.external_txn_id,
    tc.category_name,
    tp.role                    AS user_role,
    t.amount,
    t.fee,
    t.transaction_date,
    t.raw_message
FROM transaction_participants AS tp
JOIN transactions              AS t
  ON tp.transaction_id = t.transaction_id
JOIN transaction_categories    AS tc
  ON t.category_id = tc.category_id
JOIN users                     AS u
  ON tp.user_id = u.user_id
WHERE u.full_name = 'Samuel Carter'
ORDER BY t.transaction_date;

-- Purpose: Aggregate — how many transactions fall into each category?
--          GROUP BY verifies the FK integrity across all rows.
SELECT
    tc.category_name,
    COUNT(t.transaction_id) AS transaction_count
FROM transaction_categories AS tc
LEFT JOIN transactions AS t
  ON tc.category_id = t.category_id
GROUP BY tc.category_id, tc.category_name
ORDER BY transaction_count DESC;


-- ===== UPDATE =====

-- Purpose: Reassign TX1006 from "Payment to Code Holder" to
--          "Airtime Purchase" to simulate a category correction.
--          Uses a subquery so the change is not tied to a hard-coded ID.
UPDATE transactions
SET category_id = (
    SELECT category_id
    FROM transaction_categories
    WHERE category_name = 'Airtime Purchase'
)
WHERE external_txn_id = 'TX1006';

-- Verify the change
SELECT t.external_txn_id, tc.category_name
FROM transactions AS t
JOIN transaction_categories AS tc ON t.category_id = tc.category_id
WHERE t.external_txn_id = 'TX1006';

-- Purpose: Correct MTN Agent 54321's phone number to simulate fixing
--          a masked or malformed value loaded by the ETL pipeline.
UPDATE users
SET phone_number = '+250788333099'
WHERE full_name = 'MTN Agent 54321';

-- Verify the change
SELECT user_id, full_name, phone_number
FROM users
WHERE full_name = 'MTN Agent 54321';


-- ===== DELETE =====

-- Purpose: Remove the test transaction TX1006.
--          Step 1 — confirm the row exists before deletion.
SELECT t.transaction_id, t.external_txn_id, t.amount
FROM transactions AS t
WHERE t.external_txn_id = 'TX1006';

-- Step 2 — delete it.  Because fk_tp_tx is defined ON DELETE CASCADE,
--          the two transaction_participants rows for TX1006 are removed
--          automatically by MySQL.
DELETE FROM transactions
WHERE external_txn_id = 'TX1006';

-- Step 3 — confirm the row (and its participants) are gone.
SELECT t.transaction_id, t.external_txn_id
FROM transactions AS t
WHERE t.external_txn_id = 'TX1006';              -- expected: 0 rows

SELECT tp.participant_id, tp.transaction_id
FROM transaction_participants AS tp
WHERE tp.transaction_id NOT IN (
    SELECT transaction_id FROM transactions
);                                                -- expected: 0 rows (cascade worked)

-- Purpose: Demonstrate FK protection on users.
--          fk_tp_user has NO ON DELETE CASCADE, so trying to delete a user
--          who still has rows in transaction_participants must fail.
--          MySQL raises: ERROR 1451 (23000) — Cannot delete or update a parent row.
--          If this query succeeds, the FK constraint is missing — investigate.
DELETE FROM users
WHERE full_name = 'Samuel Carter';


-- ===== ANALYTICAL QUERIES =====

-- Purpose: Total RWF transacted per category — the primary business metric.
--          Identifies which transaction types carry the most monetary volume.
SELECT
    tc.category_name,
    SUM(t.amount)              AS total_amount_rwf,
    COUNT(t.transaction_id)    AS transaction_count
FROM transaction_categories AS tc
LEFT JOIN transactions AS t
  ON tc.category_id = t.category_id
GROUP BY tc.category_id, tc.category_name
ORDER BY total_amount_rwf DESC;

-- Purpose: Find the busiest transaction day.
--          Useful for spotting usage spikes or off-hours behaviour.
SELECT
    DATE(t.transaction_date)   AS txn_day,
    COUNT(t.transaction_id)    AS transactions_on_day
FROM transactions AS t
GROUP BY txn_day
ORDER BY transactions_on_day DESC, txn_day DESC
LIMIT 1;

-- Purpose: Average fee per category, highest to lowest.
--          Helps identify which transaction types are most costly for users.
SELECT
    tc.category_name,
    ROUND(AVG(t.fee), 2)       AS avg_fee_rwf
FROM transaction_categories AS tc
JOIN transactions AS t
  ON tc.category_id = t.category_id
GROUP BY tc.category_id, tc.category_name
ORDER BY avg_fee_rwf DESC;

-- Purpose: Top 5 counterparties by total amount received.
--          Reveals dominant merchants or agents in the ecosystem.
SELECT
    u.full_name,
    u.user_type,
    SUM(t.amount)              AS total_received_rwf,
    COUNT(t.transaction_id)    AS times_received
FROM users AS u
JOIN transaction_participants AS tp
  ON u.user_id = tp.user_id AND tp.role = 'RECEIVER'
JOIN transactions AS t
  ON tp.transaction_id = t.transaction_id
GROUP BY u.user_id, u.full_name, u.user_type
ORDER BY total_received_rwf DESC
LIMIT 5;


-- =====================================================================
-- SCREENSHOT CHECKLIST
-- After running each query block in your MySQL client, save a screenshot
-- of the result set with the filename shown below.
--
-- Folder : docs/screenshots/crud/
--
-- 01_insert_merchant_user.png         — result of INSERT INTO users
-- 02_insert_transaction.png           — result of INSERT INTO transactions
-- 03_insert_participants.png          — result of INSERT INTO transaction_participants
-- 04_select_payment_category.png      — Payment to Code Holder list
-- 05_select_high_value.png            — transactions with amount > 5000 RWF
-- 06_select_user_history.png          — Samuel Carter's full history via M:N join
-- 07_select_count_by_category.png     — transaction count grouped by category
-- 08_update_category.png              — TX1006 category changed (+ verify SELECT)
-- 09_update_phone_number.png          — MTN Agent phone corrected (+ verify SELECT)
-- 10_delete_before.png                — SELECT showing TX1006 exists before DELETE
-- 11_delete_after.png                 — SELECT showing TX1006 is gone after DELETE
-- 12_delete_cascade_check.png         — zero orphan participant rows after cascade
-- 13_delete_user_fk_error.png         — ERROR 1451 when deleting Samuel Carter
-- 14_analytics_total_per_category.png — total RWF per category
-- 15_analytics_busiest_day.png        — date with most transactions
-- 16_analytics_avg_fee.png            — average fee per category
-- 17_analytics_top5_receivers.png     — top 5 counterparties by received amount
-- =====================================================================
