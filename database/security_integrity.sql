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
