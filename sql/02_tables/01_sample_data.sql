/*==============================================================================
02 - Sample Data: Orders and Customers
==============================================================================*/

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

----------------------------------------------------------------------
-- Customers
----------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    CUSTOMER_ID   NUMBER       NOT NULL,
    CUSTOMER_NAME VARCHAR(100) NOT NULL,
    REGION        VARCHAR(20)  NOT NULL,
    SEGMENT       VARCHAR(20)  NOT NULL,
    JOIN_DATE     DATE         NOT NULL
) COMMENT = 'DEMO: Customer master data (Expires: 2026-03-07)';

INSERT INTO RAW_CUSTOMERS (CUSTOMER_ID, CUSTOMER_NAME, REGION, SEGMENT, JOIN_DATE)
VALUES
    (1,  'Acme Corp',         'West',    'Enterprise',  '2023-01-15'),
    (2,  'Globex Inc',        'East',    'Enterprise',  '2023-03-22'),
    (3,  'Initech LLC',       'Central', 'Mid-Market',  '2023-06-10'),
    (4,  'Umbrella Co',       'South',   'Enterprise',  '2023-08-05'),
    (5,  'Stark Industries',  'West',    'Enterprise',  '2024-01-12'),
    (6,  'Wayne Enterprises', 'East',    'Mid-Market',  '2024-02-28'),
    (7,  'Cyberdyne Systems', 'Central', 'SMB',         '2024-05-15'),
    (8,  'Oscorp',            'South',   'Mid-Market',  '2024-07-20'),
    (9,  'LexCorp',           'East',    'Enterprise',  '2024-09-01'),
    (10, 'Capsule Corp',      'West',    'SMB',         '2024-11-10');

----------------------------------------------------------------------
-- Orders
----------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW_ORDERS (
    ORDER_ID     NUMBER        NOT NULL,
    CUSTOMER_ID  NUMBER        NOT NULL,
    ORDER_DATE   DATE          NOT NULL,
    PRODUCT      VARCHAR(50)   NOT NULL,
    QUANTITY     NUMBER        NOT NULL,
    UNIT_PRICE   NUMBER(10,2)  NOT NULL,
    TOTAL_AMOUNT NUMBER(10,2)  NOT NULL,
    STATUS       VARCHAR(20)   NOT NULL
) COMMENT = 'DEMO: Customer orders (Expires: 2026-03-07)';

INSERT INTO RAW_ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, TOTAL_AMOUNT, STATUS)
VALUES
    (1001, 1,  '2025-01-10', 'Laptop',          2,  1299.99, 2599.98, 'Completed'),
    (1002, 2,  '2025-01-15', 'Monitor',          5,   499.99, 2499.95, 'Completed'),
    (1003, 3,  '2025-02-01', 'Keyboard',         10,   89.99,  899.90, 'Completed'),
    (1004, 1,  '2025-02-14', 'Docking Station',   3,  249.99,  749.97, 'Completed'),
    (1005, 4,  '2025-03-05', 'Laptop',            1, 1299.99, 1299.99, 'Completed'),
    (1006, 5,  '2025-03-20', 'Webcam',            8,  129.99, 1039.92, 'Completed'),
    (1007, 2,  '2025-04-02', 'Headset',          15,   79.99, 1199.85, 'Completed'),
    (1008, 6,  '2025-04-18', 'Mouse',            20,   49.99,  999.80, 'Completed'),
    (1009, 7,  '2025-05-01', 'Laptop',            1, 1299.99, 1299.99, 'Completed'),
    (1010, 3,  '2025-05-15', 'Monitor',           2,  499.99,  999.98, 'Completed'),
    (1011, 8,  '2025-06-01', 'Keyboard',          5,   89.99,  449.95, 'Completed'),
    (1012, 9,  '2025-06-20', 'Docking Station',   4,  249.99,  999.96, 'Completed'),
    (1013, 1,  '2025-07-05', 'Headset',          10,   79.99,  799.90, 'Shipped'),
    (1014, 10, '2025-07-15', 'Webcam',            3,  129.99,  389.97, 'Shipped'),
    (1015, 4,  '2025-08-01', 'Laptop',            2, 1299.99, 2599.98, 'Shipped'),
    (1016, 5,  '2025-08-20', 'Monitor',           6,  499.99, 2999.94, 'Processing'),
    (1017, 6,  '2025-09-01', 'Mouse',            25,   49.99, 1249.75, 'Processing'),
    (1018, 2,  '2025-09-15', 'Keyboard',          8,   89.99,  719.92, 'Processing'),
    (1019, 7,  '2025-10-01', 'Docking Station',   2,  249.99,  499.98, 'Cancelled'),
    (1020, 3,  '2025-10-20', 'Laptop',            1, 1299.99, 1299.99, 'Completed'),
    (1021, 9,  '2025-11-05', 'Headset',          12,   79.99,  959.88, 'Completed'),
    (1022, 8,  '2025-11-18', 'Webcam',            4,  129.99,  519.96, 'Completed'),
    (1023, 10, '2025-12-01', 'Monitor',           3,  499.99, 1499.97, 'Completed'),
    (1024, 1,  '2025-12-15', 'Mouse',            30,   49.99, 1499.70, 'Completed'),
    (1025, 4,  '2026-01-10', 'Laptop',            3, 1299.99, 3899.97, 'Processing');
