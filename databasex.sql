-- MYSQL 9.4 / CLOUD-SAFE VERSION

-- This version removes CHECK constraints because some cloud-hosted
-- MySQL 9.x providers reject CHECK constraints in specific FK or
-- cross-column situations.
--
-- Relational integrity is still enforced through:
-- - PRIMARY KEY constraints
-- - FOREIGN KEY constraints
-- - UNIQUE constraints
-- - NOT NULL constraints
-- - ENUMs
-- - stored procedure validation
-- - application-layer validation in the FastAPI/Streamlit layer
--
-- MMO Multi-Layer Database System
-- MySQL 8.0+ compatible
-- Author/User ID: daf222
-- Cloud-hosted MySQL note:
-- Database creation/drop is usually handled by the provider.
-- Select your existing database/schema in MySQL Workbench before running this file.
 DROP DATABASE IF EXISTS mmo_game_db_daf222;
 CREATE DATABASE mmo_game_db_daf222;
 USE mmo_game_db_daf222;

-- 1. CORE ACCOUNT / CHARACTER TABLES

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE level_thresholds (
    level INT PRIMARY KEY,
    exp_required INT NOT NULL
);

-- Note: level is validated through the foreign key to level_thresholds.
-- do not add here because some cloud MySQL providers reject CHECK + FK referential actions on the same column - some struggle is necessary

CREATE TABLE characters (
    char_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    class_id INT NOT NULL,
    name VARCHAR(80) NOT NULL UNIQUE,
    level INT NOT NULL DEFAULT 1,
    current_exp INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_char_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_char_class
        FOREIGN KEY (class_id) REFERENCES classes(class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_char_level
        FOREIGN KEY (level) REFERENCES level_thresholds(level)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE login_logs (
    login_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    device VARCHAR(120),
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_login_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 2. ITEMS / CURRENCY / OWNERSHIP TABLES

CREATE TABLE items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(120) NOT NULL UNIQUE,
    rarity ENUM('Common', 'Uncommon', 'Rare', 'Epic', 'Legendary') NOT NULL,
    base_price DECIMAL(12,2) NOT NULL
);

CREATE TABLE currencies (
    currency_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_name VARCHAR(80) NOT NULL UNIQUE,
    is_tradable BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE inventories (
    char_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,

    PRIMARY KEY (char_id, item_id),

    CONSTRAINT fk_inv_char
        FOREIGN KEY (char_id) REFERENCES characters(char_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_inv_item
        FOREIGN KEY (item_id) REFERENCES items(item_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE character_currencies (
    char_id INT NOT NULL,
    currency_id INT NOT NULL,
    balance DECIMAL(14,2) NOT NULL DEFAULT 0,

    PRIMARY KEY (char_id, currency_id),

    CONSTRAINT fk_charcur_char
        FOREIGN KEY (char_id) REFERENCES characters(char_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_charcur_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. MONSTERS / LOOT SYSTEM

CREATE TABLE monsters (
    monster_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    level INT NOT NULL,
    exp_reward INT NOT NULL
);

CREATE TABLE loot_item_pools (
    pool_id INT AUTO_INCREMENT PRIMARY KEY,
    monster_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    drop_rate DECIMAL(5,4) NOT NULL,

    CONSTRAINT fk_lootitempool_monster
        FOREIGN KEY (monster_id) REFERENCES monsters(monster_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_lootitempool_item
        FOREIGN KEY (item_id) REFERENCES items(item_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT uq_monster_item_drop UNIQUE (monster_id, item_id)
);

-- Note: max_amount should be greater than or equal to min_amount!

CREATE TABLE loot_currency_pools (
    pool_id INT AUTO_INCREMENT PRIMARY KEY,
    monster_id INT NOT NULL,
    currency_id INT NOT NULL,
    min_amount DECIMAL(12,2) NOT NULL,
    max_amount DECIMAL(12,2) NOT NULL,
    drop_rate DECIMAL(5,4) NOT NULL,

    CONSTRAINT fk_lootcurrpool_monster
        FOREIGN KEY (monster_id) REFERENCES monsters(monster_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_lootcurrpool_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT uq_monster_currency_drop UNIQUE (monster_id, currency_id)
);

CREATE TABLE loot_item_logs (
    log_i_id INT AUTO_INCREMENT PRIMARY KEY,
    char_id INT NOT NULL,
    monster_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lootitemlog_char
        FOREIGN KEY (char_id) REFERENCES characters(char_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_lootitemlog_monster
        FOREIGN KEY (monster_id) REFERENCES monsters(monster_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_lootitemlog_item
        FOREIGN KEY (item_id) REFERENCES items(item_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE loot_currency_logs (
    log_c_id INT AUTO_INCREMENT PRIMARY KEY,
    char_id INT NOT NULL,
    monster_id INT NOT NULL,
    currency_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lootcurrlog_char
        FOREIGN KEY (char_id) REFERENCES characters(char_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_lootcurrlog_monster
        FOREIGN KEY (monster_id) REFERENCES monsters(monster_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_lootcurrlog_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 4. TRANSACTION / TRADE SYSTEM

CREATE TABLE transactions
(
    trans_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_char_id INT NOT NULL,
    receiver_char_id INT NOT NULL,
    transaction_type ENUM('TRADE', 'GIFT', 'MARKET_SALE', 'ADMIN_ADJUSTMENT') NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_trans_sender
        FOREIGN KEY (sender_char_id) REFERENCES characters(char_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_trans_receiver
        FOREIGN KEY (receiver_char_id) REFERENCES characters(char_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE transaction_items (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL,

    CONSTRAINT fk_transitem_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(trans_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_transitem_item
        FOREIGN KEY (item_id) REFERENCES items(item_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE transaction_currencies (
    trade_curr_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    currency_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_transcurr_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(trans_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_transcurr_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. INDEXES FOR PERFORM / MONITORING

CREATE INDEX idx_char_user ON characters(user_id);
CREATE INDEX idx_login_user_time ON login_logs(user_id, timestamp);
CREATE INDEX idx_login_ip_time ON login_logs(ip_address, timestamp);
CREATE INDEX idx_loot_item_char_time ON loot_item_logs(char_id, timestamp);
CREATE INDEX idx_loot_currency_char_time ON loot_currency_logs(char_id, timestamp);
CREATE INDEX idx_transactions_sender_time ON transactions(sender_char_id, timestamp);
CREATE INDEX idx_transactions_receiver_time ON transactions(receiver_char_id, timestamp);
CREATE INDEX idx_inventory_item ON inventories(item_id);
CREATE INDEX idx_character_currency ON character_currencies(currency_id);

-- 6. SAMPLE DATA

INSERT INTO level_thresholds (level, exp_required) VALUES
(1, 0),
(2, 100),
(3, 300),
(4, 600),
(5, 1000),
(6, 1500),
(7, 2200),
(8, 3100),
(9, 4200),
(10, 5500);

INSERT INTO classes (class_name) VALUES
('Warrior'),
('Mage'),
('Rogue'),
('Cleric'),
('Ranger');

INSERT INTO users (email, password_hash, create_time) VALUES
('donat.player@example.com', 'hashed_pw_001', '2026-04-01 09:15:00'),
('lena.guild@example.com', 'hashed_pw_002', '2026-04-02 10:20:00'),
('max.trader@example.com', 'hashed_pw_003', '2026-04-03 14:45:00'),
('sara.raid@example.com', 'hashed_pw_004', '2026-04-04 18:30:00'),
('admin.ops@example.com', 'hashed_pw_admin', '2026-04-05 08:00:00');

INSERT INTO characters (user_id, class_id, name, level, current_exp) VALUES
(1, 1, 'IronDon', 5, 1120),
(1, 3, 'ShadowSprint', 3, 350),
(2, 2, 'LunaFlare', 6, 1700),
(3, 5, 'MarketHawk', 4, 720),
(4, 4, 'HolySara', 7, 2500),
(5, 2, 'AdminOracle', 10, 9000);

INSERT INTO login_logs (user_id, ip_address, device, timestamp) VALUES
(1, '172.56.21.10', 'Windows Laptop', '2026-04-20 19:01:00'),
(1, '172.56.21.10', 'Windows Laptop', '2026-04-21 20:14:00'),
(2, '98.112.44.8', 'MacBook', '2026-04-21 18:22:00'),
(3, '185.199.110.50', 'Linux Desktop', '2026-04-21 23:40:00'),
(3, '45.88.12.77', 'Unknown Device', '2026-04-22 00:05:00'),
(3, '45.88.12.77', 'Unknown Device', '2026-04-22 00:09:00'),
(4, '73.18.90.3', 'iPad', '2026-04-22 11:15:00'),
(5, '10.0.0.5', 'Admin Console', '2026-04-22 12:00:00');

INSERT INTO items (item_name, rarity, base_price) VALUES
('Rusty Sword', 'Common', 15.00),
('Iron Shield', 'Common', 35.00),
('Forest Bow', 'Uncommon', 80.00),
('Mana Crystal', 'Rare', 250.00),
('Dragonfang Dagger', 'Epic', 900.00),
('Phoenix Staff', 'Legendary', 2500.00),
('Healing Potion', 'Common', 10.00),
('Shadow Cloak', 'Epic', 1200.00);

INSERT INTO currencies (currency_name, is_tradable) VALUES
('Gold', TRUE),
('Gems', TRUE),
('Raid Tokens', FALSE),
('Honor Points', FALSE);

INSERT INTO inventories (char_id, item_id, quantity) VALUES
(1, 1, 2),
(1, 2, 1),
(1, 7, 5),
(2, 5, 1),
(2, 8, 1),
(3, 4, 4),
(3, 6, 1),
(4, 3, 2),
(4, 7, 10),
(5, 2, 1),
(5, 7, 8),
(6, 6, 3);

INSERT INTO character_currencies (char_id, currency_id, balance) VALUES
(1, 1, 1500.00),
(1, 2, 35.00),
(1, 3, 12.00),
(2, 1, 420.00),
(2, 2, 5.00),
(3, 1, 3200.00),
(3, 2, 200.00),
(4, 1, 8200.00),
(4, 2, 500.00),
(5, 1, 900.00),
(5, 4, 80.00),
(6, 1, 99999.00),
(6, 2, 999.00);

INSERT INTO monsters (name, level, exp_reward) VALUES
('Forest Goblin', 1, 25),
('Cave Troll', 3, 90),
('Crystal Wraith', 5, 180),
('Molten Drake', 7, 350),
('Ancient Dragon', 10, 1000);

INSERT INTO loot_item_pools (monster_id, item_id, quantity, drop_rate) VALUES
(1, 1, 1, 0.3500),
(1, 7, 1, 0.6000),
(2, 2, 1, 0.2500),
(2, 3, 1, 0.1500),
(3, 4, 1, 0.3000),
(4, 5, 1, 0.0800),
(5, 6, 1, 0.0300),
(5, 8, 1, 0.0500);

INSERT INTO loot_currency_pools (monster_id, currency_id, min_amount, max_amount, drop_rate) VALUES
(1, 1, 5.00, 15.00, 0.9000),
(2, 1, 20.00, 60.00, 0.8500),
(3, 1, 75.00, 160.00, 0.8000),
(4, 1, 200.00, 450.00, 0.7000),
(5, 1, 1000.00, 2500.00, 0.5000),
(5, 2, 10.00, 35.00, 0.2000);

INSERT INTO loot_item_logs (char_id, monster_id, item_id, quantity, timestamp) VALUES
(1, 1, 7, 2, '2026-04-20 20:00:00'),
(1, 2, 2, 1, '2026-04-20 20:20:00'),
(3, 3, 4, 1, '2026-04-21 21:30:00'),
(4, 5, 6, 1, '2026-04-21 22:10:00'),
(4, 5, 8, 1, '2026-04-21 22:11:00'),
(6, 5, 6, 2, '2026-04-22 12:05:00');

INSERT INTO loot_currency_logs (char_id, monster_id, currency_id, amount, timestamp) VALUES
(1, 1, 1, 12.00, '2026-04-20 20:00:00'),
(1, 2, 1, 55.00, '2026-04-20 20:20:00'),
(3, 3, 1, 140.00, '2026-04-21 21:30:00'),
(4, 5, 1, 2200.00, '2026-04-21 22:10:00'),
(4, 5, 2, 25.00, '2026-04-21 22:10:00'),
(6, 5, 1, 8000.00, '2026-04-22 12:05:00');

INSERT INTO transactions (sender_char_id, receiver_char_id, transaction_type, timestamp) VALUES
(4, 1, 'TRADE', '2026-04-21 23:00:00'),
(3, 2, 'GIFT', '2026-04-22 00:10:00'),
(6, 4, 'ADMIN_ADJUSTMENT', '2026-04-22 12:10:00'),
(4, 3, 'MARKET_SALE', '2026-04-22 13:45:00');

INSERT INTO transaction_items (transaction_id, item_id, quantity) VALUES
(1, 7, 3),
(2, 5, 1),
(4, 3, 1);

INSERT INTO transaction_currencies (transaction_id, currency_id, amount) VALUES
(1, 1, 300.00),
(2, 1, 5000.00),
(3, 1, 25000.00),
(4, 2, 100.00);

-- 7. VIEWS FOR ANALYTICS / AI AGENT READ QUERIES

CREATE OR REPLACE VIEW vw_character_overview AS
SELECT
    c.char_id,
    c.name AS character_name,
    u.email AS account_email,
    cl.class_name,
    c.level,
    c.current_exp,
    lt.exp_required AS exp_required_for_current_level
FROM characters c
JOIN users u ON c.user_id = u.user_id
JOIN classes cl ON c.class_id = cl.class_id
JOIN level_thresholds lt ON c.level = lt.level;

CREATE OR REPLACE VIEW vw_inventory_value AS
SELECT
    c.char_id,
    c.name AS character_name,
    SUM(i.base_price * inv.quantity) AS total_inventory_value
FROM characters c
JOIN inventories inv ON c.char_id = inv.char_id
JOIN items i ON inv.item_id = i.item_id
GROUP BY c.char_id, c.name;

CREATE OR REPLACE VIEW vw_currency_balances AS
SELECT
    c.char_id,
    c.name AS character_name,
    cur.currency_name,
    cur.is_tradable,
    cc.balance
FROM character_currencies cc
JOIN characters c ON cc.char_id = c.char_id
JOIN currencies cur ON cc.currency_id = cur.currency_id;

CREATE OR REPLACE VIEW vw_transaction_summary AS
SELECT
    t.trans_id,
    sender.name AS sender_character,
    receiver.name AS receiver_character,
    t.transaction_type,
    t.timestamp,
    COALESCE(SUM(tc.amount), 0) AS total_currency_amount,
    COALESCE(SUM(ti.quantity), 0) AS total_item_quantity
FROM transactions t
JOIN characters sender ON t.sender_char_id = sender.char_id
JOIN characters receiver ON t.receiver_char_id = receiver.char_id
LEFT JOIN transaction_currencies tc ON t.trans_id = tc.transaction_id
LEFT JOIN transaction_items ti ON t.trans_id = ti.transaction_id
GROUP BY
    t.trans_id,
    sender.name,
    receiver.name,
    t.transaction_type,
    t.timestamp;

CREATE OR REPLACE VIEW vw_suspicious_large_currency_transfers AS
SELECT
    t.trans_id,
    sender.name AS sender_character,
    receiver.name AS receiver_character,
    cur.currency_name,
    tc.amount,
    t.transaction_type,
    t.timestamp
FROM transactions t
JOIN transaction_currencies tc ON t.trans_id = tc.transaction_id
JOIN currencies cur ON tc.currency_id = cur.currency_id
JOIN characters sender ON t.sender_char_id = sender.char_id
JOIN characters receiver ON t.receiver_char_id = receiver.char_id
WHERE tc.amount >= 5000;

CREATE OR REPLACE VIEW vw_suspicious_login_activity AS
SELECT
    u.user_id,
    u.email,
    COUNT(DISTINCT l.ip_address) AS different_ip_count,
    COUNT(*) AS login_count,
    MIN(l.timestamp) AS first_seen,
    MAX(l.timestamp) AS last_seen
FROM users u
JOIN login_logs l ON u.user_id = l.user_id
GROUP BY u.user_id, u.email
HAVING COUNT(DISTINCT l.ip_address) >= 2;

CREATE OR REPLACE VIEW vw_monster_drop_rules AS
SELECT
    m.name AS monster_name,
    m.level AS monster_level,
    i.item_name,
    i.rarity,
    lip.quantity,
    lip.drop_rate
FROM loot_item_pools lip
JOIN monsters m ON lip.monster_id = m.monster_id
JOIN items i ON lip.item_id = i.item_id;

-- 8. STORED PROCEDURES

DELIMITER $$

CREATE PROCEDURE sp_add_currency_to_character (
    IN p_char_id INT,
    IN p_currency_id INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Amount must be greater than zero.';
    END IF;

    INSERT INTO character_currencies (char_id, currency_id, balance)
    VALUES (p_char_id, p_currency_id, p_amount)
    ON DUPLICATE KEY UPDATE balance = balance + p_amount;
END $$

CREATE PROCEDURE sp_add_item_to_inventory (
    IN p_char_id INT,
    IN p_item_id INT,
    IN p_quantity INT
)
BEGIN
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Quantity must be greater than zero.';
    END IF;

    INSERT INTO inventories (char_id, item_id, quantity)
    VALUES (p_char_id, p_item_id, p_quantity)
    ON DUPLICATE KEY UPDATE quantity = quantity + p_quantity;
END $$

CREATE PROCEDURE sp_log_currency_drop (
    IN p_char_id INT,
    IN p_monster_id INT,
    IN p_currency_id INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Loot amount must be greater than zero.';
    END IF;

    INSERT INTO loot_currency_logs (char_id, monster_id, currency_id, amount)
    VALUES (p_char_id, p_monster_id, p_currency_id, p_amount);

    CALL sp_add_currency_to_character(p_char_id, p_currency_id, p_amount);
END $$

CREATE PROCEDURE sp_log_item_drop (
    IN p_char_id INT,
    IN p_monster_id INT,
    IN p_item_id INT,
    IN p_quantity INT
)
BEGIN
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Loot quantity must be greater than zero.';
    END IF;

    INSERT INTO loot_item_logs (char_id, monster_id, item_id, quantity)
    VALUES (p_char_id, p_monster_id, p_item_id, p_quantity);

    CALL sp_add_item_to_inventory(p_char_id, p_item_id, p_quantity);
END $$

CREATE PROCEDURE sp_create_currency_transfer (
    IN p_sender_char_id INT,
    IN p_receiver_char_id INT,
    IN p_currency_id INT,
    IN p_amount DECIMAL(12,2),
    IN p_transaction_type VARCHAR(30)
)
BEGIN
    DECLARE v_sender_balance DECIMAL(14,2);
    DECLARE v_is_tradable BOOLEAN;
    DECLARE v_trans_id INT;

    IF p_sender_char_id = p_receiver_char_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sender and receiver cannot be the same character.';
    END IF;

    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transfer amount must be greater than zero.';
    END IF;

    SELECT is_tradable
    INTO v_is_tradable
    FROM currencies
    WHERE currency_id = p_currency_id;

    IF v_is_tradable = FALSE AND p_transaction_type <> 'ADMIN_ADJUSTMENT' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This currency is not tradable.';
    END IF;

    SELECT balance
    INTO v_sender_balance
    FROM character_currencies
    WHERE char_id = p_sender_char_id
      AND currency_id = p_currency_id
    FOR UPDATE;

    IF v_sender_balance IS NULL OR v_sender_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sender does not have enough currency.';
    END IF;

    START TRANSACTION;

        UPDATE character_currencies
        SET balance = balance - p_amount
        WHERE char_id = p_sender_char_id
          AND currency_id = p_currency_id;

        INSERT INTO character_currencies (char_id, currency_id, balance)
        VALUES (p_receiver_char_id, p_currency_id, p_amount)
        ON DUPLICATE KEY UPDATE balance = balance + p_amount;

        INSERT INTO transactions (sender_char_id, receiver_char_id, transaction_type)
        VALUES (p_sender_char_id, p_receiver_char_id, p_transaction_type);

        SET v_trans_id = LAST_INSERT_ID();

        INSERT INTO transaction_currencies (transaction_id, currency_id, amount)
        VALUES (v_trans_id, p_currency_id, p_amount);

    COMMIT;
END $$
DELIMITER ;

-- 9. TEST QUERIES FOR PROFESSOR / DEMO

-- Character overview
SELECT * FROM vw_character_overview;
-- Total value of each character's inventory
SELECT * FROM vw_inventory_value
ORDER BY total_inventory_value DESC;
-- Suspicious large money movement
SELECT * FROM vw_suspicious_large_currency_transfers;
-- Suspicious account logins from multiple IP addresses
SELECT * FROM vw_suspicious_login_activity;
-- Monster loot rules
SELECT * FROM vw_monster_drop_rules
ORDER BY monster_level, drop_rate DESC;

-- Example safe stored procedure test:
-- CALL sp_log_currency_drop(1, 1, 1, 25.00);
-- CALL sp_log_item_drop(1, 1, 7, 1);
-- CALL sp_create_currency_transfer(1, 2, 1, 100.00, 'TRADE');

-- Final verification
SHOW TABLES;


SELECT * FROM vw_character_overview;
SELECT * FROM vw_inventory_value ORDER BY total_inventory_value DESC;
SELECT * FROM vw_suspicious_large_currency_transfers;
SELECT * FROM vw_suspicious_login_activity;