USE momo_sms;

-- CHECK CONSTRAINTS

ALTER TABLE transactions
  ADD CONSTRAINT chk_amount_non_negative
    CHECK (amount >= 0);

ALTER TABLE transactions
  ADD CONSTRAINT chk_fee_non_negative
    CHECK (fee >= 0);

ALTER TABLE transactions
  ADD CONSTRAINT chk_balance_non_negative
    CHECK (new_balance >= 0);

ALTER TABLE transactions
  ADD CONSTRAINT chk_fee_not_exceed_amount
    CHECK (fee <= amount);


-- TRIGGERS

DELIMITER $$

CREATE TRIGGER trg_after_tx_insert
  AFTER INSERT ON transactions
  FOR EACH ROW
BEGIN
  INSERT INTO system_logs (transaction_id, log_level, message)
  VALUES (
    NEW.transaction_id,
    'INFO',
    CONCAT('Transaction inserted: ', COALESCE(NEW.external_txn_id, 'N/A'),
           ' | amount: ', NEW.amount,
           ' | fee: ', NEW.fee)
  );
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_before_tx_update
  BEFORE UPDATE ON transactions
  FOR EACH ROW
BEGIN
  IF NEW.amount < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Update rejected: transaction amount cannot be negative.';
  END IF;

  IF NEW.fee > NEW.amount THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Update rejected: fee cannot exceed the transaction amount.';
  END IF;
END$$

DELIMITER ;

-- =====================================================================
-- SECTION 3 — VIEWS
-- =====================================================================

CREATE OR REPLACE VIEW v_transaction_summary AS
SELECT
  t.transaction_id,
  t.external_txn_id,
  tc.category_name,
  t.amount,
  t.fee,
  t.new_balance,
  t.transaction_date,
  u.full_name      AS participant_name,
  u.phone_number   AS participant_phone,
  u.user_type      AS participant_type,
  tp.role          AS participant_role
FROM transactions             t
JOIN transaction_categories  tc ON tc.category_id    = t.category_id
JOIN transaction_participants tp ON tp.transaction_id = t.transaction_id
JOIN users                    u  ON u.user_id         = tp.user_id;

CREATE OR REPLACE VIEW v_daily_totals AS
SELECT
  DATE(transaction_date)  AS txn_day,
  COUNT(*)                AS txn_count,
  SUM(amount)             AS total_amount,
  SUM(fee)                AS total_fees
FROM transactions
GROUP BY DATE(transaction_date)
ORDER BY txn_day;
