-- The Business Problem of Project
-- The bank has customer, account, transaction, loan, repayment, branch and card data distributed across multiple relational tables. 
-- Management needs to understand customer behavior, account and transaction activity, loan performance, repayment behavior and 
-- banking product engagement. The objective of this project is to analyze the available data using MySQL and generate meaningful
--  business insights that can support data-driven banking decisions.


create database Retail_Banking_Transaction;
use Retail_Banking_Transaction;

CREATE TABLE branches (
    branch_id VARCHAR(20) PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    region VARCHAR(50),
    opening_date varchar(50),
    employee_count INT
);

CREATE TABLE accounts (
    account_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    branch_id VARCHAR(20) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    open_date varchar(50),
    close_date varchar(50),
    current_balance DECIMAL(15,2),
    interest_rate DECIMAL(6,2),
    overdraft_limit DECIMAL(15,2),
    status VARCHAR(20),

    FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

CREATE TABLE customers (
    customer_id     VARCHAR(10) PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    date_of_birth   varchar(50),
    gender          VARCHAR(20),
    city            VARCHAR(100),
    state           VARCHAR(50),
    customer_since  DATE NOT NULL,
    kyc_status      VARCHAR(30) NOT NULL,
    segment         VARCHAR(50) NOT NULL,
    annual_income   DECIMAL(15,2),
    credit_score    INT,
    is_active       VARCHAR(5) NOT NULL DEFAULT 'Yes',
    CONSTRAINT chk_customer_income CHECK (annual_income >= 0),
    CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 0 AND 1000)
);

CREATE TABLE loans (
    loan_id               VARCHAR(15) PRIMARY KEY,
    customer_id           VARCHAR(10) NOT NULL,
    branch_id             VARCHAR(10) NOT NULL,
    loan_type             VARCHAR(50) NOT NULL,
    principal_amount      DECIMAL(18,2) NOT NULL,
    interest_rate         DECIMAL(7,3) NOT NULL,
    tenure_months         INT NOT NULL,
    disbursement_date     varchar(50),
    maturity_date         varchar(50),
    emi_amount            DECIMAL(18,2) NOT NULL,
    outstanding_balance   DECIMAL(18,2) NOT NULL,
    loan_status           VARCHAR(30) NOT NULL,
    purpose               VARCHAR(100),
    CONSTRAINT fk_loans_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_loans_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT chk_loan_principal CHECK (principal_amount >= 0),
    CONSTRAINT chk_loan_tenure CHECK (tenure_months > 0),
    CONSTRAINT chk_loan_emi CHECK (emi_amount >= 0),
    CONSTRAINT chk_loan_outstanding CHECK (outstanding_balance >= 0),
    CONSTRAINT chk_loan_dates CHECK (maturity_date >= disbursement_date)
);

CREATE TABLE loan_payments (
    payment_id          VARCHAR(15) PRIMARY KEY,
    loan_id             VARCHAR(15) NOT NULL,
    payment_date        varchar(50),
    scheduled_amount    DECIMAL(18,2) NOT NULL,
    paid_amount         DECIMAL(18,2) NOT NULL DEFAULT 0,
    principal_paid     DECIMAL(18,2) NOT NULL DEFAULT 0,
    interest_paid      DECIMAL(18,2) NOT NULL DEFAULT 0,
    penalty             DECIMAL(18,2) NOT NULL DEFAULT 0,
    days_late           INT NOT NULL DEFAULT 0,
    payment_method      VARCHAR(50),
    status              VARCHAR(30) NOT NULL,
    CONSTRAINT fk_payments_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    CONSTRAINT chk_scheduled CHECK (scheduled_amount >= 0),
    CONSTRAINT chk_paid CHECK (paid_amount >= 0),
    CONSTRAINT chk_principal_paid CHECK (principal_paid >= 0),
    CONSTRAINT chk_interest_paid CHECK (interest_paid >= 0),
    CONSTRAINT chk_penalty CHECK (penalty >= 0),
    CONSTRAINT chk_days_late CHECK (days_late >= 0)
);


CREATE TABLE cards (
    card_id                VARCHAR(20) PRIMARY KEY,
    account_id             VARCHAR(15) NOT NULL,
    card_type              VARCHAR(30) NOT NULL,
    issue_date             varchar(50),
    expiry_date            varchar(50),
    credit_limit            DECIMAL(18,2) NOT NULL DEFAULT 0,
    outstanding_balance    DECIMAL(18,2) NOT NULL DEFAULT 0,
    reward_points           INT NOT NULL DEFAULT 0,
    is_active               VARCHAR(5) NOT NULL DEFAULT 'Yes',
    network                 VARCHAR(30),
    CONSTRAINT fk_cards_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    CONSTRAINT chk_card_limit CHECK (credit_limit >= 0),
    CONSTRAINT chk_card_outstanding CHECK (outstanding_balance >= 0),
    CONSTRAINT chk_reward_points CHECK (reward_points >= 0),
    CONSTRAINT chk_card_dates CHECK (expiry_date >= issue_date)
);


CREATE TABLE transactions (
    transaction_id    VARCHAR(20) PRIMARY KEY,
    account_id        VARCHAR(15) NOT NULL,
    transaction_date  varchar(50),
    transaction_time  TIME NOT NULL,
    transaction_type  VARCHAR(50) NOT NULL,
    amount            DECIMAL(18,2) NOT NULL,
    channel           VARCHAR(50) NOT NULL,
    description       VARCHAR(255),
    balance_after     DECIMAL(18,2),
    status            VARCHAR(30) NOT NULL,
    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    CONSTRAINT chk_transaction_amount CHECK (amount >= 0)
);

use Retail_Banking_Transaction;

-- 1.	The Customer team wants to identify customers and understand which customer segment they belong to. What information would you need?
--  All customers and their segment
-- Customers
--    ↓
-- Customer demographic information
--    ↓
-- Income / Credit Score / Activity
--    ↓
-- Create analytical segments
--    ↓
-- Compare customer groups

SELECT
    CASE
        WHEN annual_income < 30000 THEN 'Low Income'
        WHEN annual_income BETWEEN 30000 AND 70000 THEN 'Middle Income'
        WHEN annual_income > 70000 THEN 'High Income'
    END AS income_segment,
    COUNT(*) AS customer_count
FROM customers
GROUP BY income_segment
ORDER BY customer_count DESC;

-- 2.	Management wants to identify customers who have more than one bank account. Which tables and columns would you need?-- 
SELECT
    customer_id,
    COUNT(account_id) AS total_accounts
FROM accounts
GROUP BY customer_id
HAVING COUNT(account_id) > 1;

-- If you want customer names
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(a.account_id) AS total_accounts
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(a.account_id) > 1;

-- Sprint 3: Basic Analysis / Data Exploration
-- Q.11. What is the total number of customers?
SELECT COUNT(*) AS total_customers FROM customers;

-- Q.12.what is the total number of accounts?
select count(*) as total_accounts from accounts;

-- Q.13.What are the different account types available?
SELECT account_type, COUNT(*) AS account_count
FROM accounts
GROUP BY account_type
ORDER BY account_count DESC;

-- Q.14.How many customers are currently active?
SELECT COUNT(*) AS active_customers
FROM customers
WHERE is_active = 'Yes';

-- Q.15.What are the different transaction types available?
SELECT transaction_type, COUNT(*) AS transaction_count
FROM transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;

-- Q.16.What is the total amount of completed transactions?
SELECT SUM(amount) AS total_completed_transaction_amount
FROM transactions
WHERE status = 'Completed';

-- Q.17.What are the different loan types available?
SELECT loan_type, COUNT(*) AS loan_count
FROM loans
GROUP BY loan_type
ORDER BY loan_count DESC;

-- Q.18.What is the total number of loans?
SELECT COUNT(*) AS total_loans FROM loans;

-- Q.19.What are the different card types available?
SELECT card_type, COUNT(*) AS card_count
FROM cards
GROUP BY card_type
ORDER BY card_count DESC;

-- Q.20.What is the total outstanding loan balance?
SELECT SUM(outstanding_balance) AS total_outstanding_loan_balance
FROM loans;

-- Sprint 4: Objective-Based Analysis
-- Q.●	Compare customers across different segments.
SELECT segment, COUNT(*) AS customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers
FROM customers
GROUP BY segment
ORDER BY customers DESC;

-- Q.●	Look at customer demographics
SELECT segment,
       COUNT(*) AS customers,
       ROUND(AVG(annual_income),2) AS avg_income,
       ROUND(AVG(credit_score),2) AS avg_credit_score,
       ROUND(MIN(credit_score),2) AS min_credit_score,
       ROUND(MAX(credit_score),2) AS max_credit_score
FROM customers
GROUP BY segment
ORDER BY avg_income DESC;

-- Q.●	Compare customers across cities and states.
SELECT state, COUNT(*) AS customers,
       ROUND(AVG(annual_income),2) AS avg_income,
       ROUND(AVG(credit_score),2) AS avg_credit_score
FROM customers
GROUP BY state
ORDER BY customers DESC;

-- Q.●	Examine income and credit-score differences.
SELECT segment, kyc_status, COUNT(*) AS customers
FROM customers
GROUP BY segment, kyc_status
ORDER BY segment, customers DESC;

-- Q.●	Understand customer tenure with the bank.
SET @as_of_date = (SELECT MAX(transaction_date) FROM transactions);

SELECT segment,
       COUNT(*) AS customers,
       ROUND(AVG(DATEDIFF(@as_of_date, customer_since)/365.25),2) AS avg_tenure_years
FROM customers
GROUP BY segment
ORDER BY avg_tenure_years DESC;

-- Q.Active customer rate by segment
SELECT segment,
       COUNT(*) AS total_customers,
       SUM(is_active='Yes') AS active_customers,
       ROUND(100 * AVG(is_active='Yes'),2) AS active_rate_pct
FROM customers
GROUP BY segment
ORDER BY active_rate_pct DESC;

-- 4.2 Understand Account Usage and Branch Activity
-- ●	Compare different account types.
SELECT account_type,
       COUNT(*) AS accounts,
       ROUND(SUM(current_balance),2) AS total_balance,
       ROUND(AVG(current_balance),2) AS avg_balance,
       ROUND(AVG(interest_rate),2) AS avg_interest_rate
FROM accounts
GROUP BY account_type
ORDER BY total_balance DESC;

-- ●	Compare account activity across customers.
SELECT status, COUNT(*) AS accounts,
       ROUND(SUM(current_balance),2) AS total_balance
FROM accounts
GROUP BY status
ORDER BY accounts DESC;

-- Q.●	Compare account activity across branches.
SELECT b.branch_name, a.account_type,
       COUNT(*) AS accounts,
       ROUND(SUM(a.current_balance),2) AS total_balance
FROM branches b
JOIN accounts a ON b.branch_id=a.branch_id
GROUP BY b.branch_name, a.account_type
ORDER BY b.branch_name, total_balance DESC;

-- Q. Branch account activity
SELECT b.branch_id, b.branch_name, b.city, b.state, b.region,
       COUNT(a.account_id) AS accounts,
       ROUND(SUM(a.current_balance),2) AS total_balance,
       ROUND(AVG(a.current_balance),2) AS avg_balance
FROM branches b
LEFT JOIN accounts a ON b.branch_id=a.branch_id
GROUP BY b.branch_id, b.branch_name, b.city, b.state, b.region
ORDER BY total_balance DESC;

-- 
-- Q. Customers with more than one account
SELECT c.customer_id,
       CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       COUNT(a.account_id) AS account_count,
       ROUND(SUM(a.current_balance),2) AS total_balance
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(a.account_id) > 1
ORDER BY account_count DESC, total_balance DESC;

-- ●	Look at interest rates across account types.
SELECT account_type,
       ROUND(MIN(interest_rate),2) AS min_rate,
       ROUND(AVG(interest_rate),2) AS avg_rate,
       ROUND(MAX(interest_rate),2) AS max_rate
FROM accounts
GROUP BY account_type
ORDER BY avg_rate DESC;

-- 4.3 Analyze Transaction Patterns
-- Q1. Transaction volume and amount by type
SELECT transaction_type,
       COUNT(*) AS transaction_count,
       ROUND(SUM(CASE WHEN status='Completed' THEN amount ELSE 0 END),2) AS completed_amount,
       ROUND(AVG(CASE WHEN status='Completed' THEN amount END),2) AS avg_completed_amount
FROM transactions
GROUP BY transaction_type
ORDER BY completed_amount DESC;


-- Q2. Transaction activity by channel
SELECT channel,
       COUNT(*) AS transaction_count,
       ROUND(SUM(CASE WHEN status='Completed' THEN amount ELSE 0 END),2) AS completed_amount
FROM transactions
GROUP BY channel
ORDER BY completed_amount DESC;

-- Q3. Transaction status distribution
SELECT status, COUNT(*) AS transaction_count,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (),2) AS pct_transactions
FROM transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Q4. Common transaction descriptions
SELECT description,
       COUNT(*) AS transaction_count,
       ROUND(SUM(CASE WHEN status='Completed' THEN amount ELSE 0 END),2) AS completed_amount
FROM transactions
GROUP BY description
ORDER BY transaction_count DESC;

-- Q5. Monthly transaction activity
SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       ROUND(SUM(CASE WHEN status='Completed' THEN amount ELSE 0 END),2) AS completed_amount
FROM transactions
GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
ORDER BY transaction_month;

-- Q6. Transaction activity by customer segment
SELECT c.segment,
       COUNT(t.transaction_id) AS transaction_count,
       ROUND(SUM(CASE WHEN t.status='Completed' THEN t.amount ELSE 0 END),2) AS completed_amount,
       ROUND(AVG(CASE WHEN t.status='Completed' THEN t.amount END),2) AS avg_completed_amount
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.segment
ORDER BY completed_amount DESC;

-- Q7. Account transaction activity versus current balance
SELECT a.account_id, a.customer_id, a.account_type,
       a.current_balance,
       COUNT(t.transaction_id) AS transaction_count,
       ROUND(SUM(CASE WHEN t.status='Completed' THEN t.amount ELSE 0 END),2) AS completed_transaction_amount
FROM accounts a
LEFT JOIN transactions t ON a.account_id=t.account_id
GROUP BY a.account_id, a.customer_id, a.account_type, a.current_balance
ORDER BY completed_transaction_amount DESC;

-- 4.4 Evaluate Loan Performance and Repayment Behaviour

-- Q1. Loan portfolio by loan type
SELECT loan_type,
       COUNT(*) AS loans,
       ROUND(SUM(principal_amount),2) AS total_principal,
       ROUND(SUM(outstanding_balance),2) AS total_outstanding,
       ROUND(AVG(outstanding_balance),2) AS avg_outstanding
FROM loans
GROUP BY loan_type
ORDER BY total_outstanding DESC;

-- Q2. Loan status distribution
SELECT loan_status, COUNT(*) AS loans,
       ROUND(SUM(outstanding_balance),2) AS total_outstanding
FROM loans
GROUP BY loan_status
ORDER BY loans DESC;

-- Q3. Loan purpose analysis
SELECT purpose,
       COUNT(*) AS loans,
       ROUND(AVG(principal_amount),2) AS avg_principal,
       ROUND(SUM(outstanding_balance),2) AS total_outstanding
FROM loans
GROUP BY purpose
ORDER BY total_outstanding DESC;


-- Q4. Loans with repayment delays
SELECT l.loan_id, l.customer_id, l.loan_type, l.loan_status,
       COUNT(p.payment_id) AS payment_count,
       SUM(p.days_late > 0) AS late_payment_count,
       SUM(p.status='Missed') AS missed_payment_count,
       ROUND(SUM(p.penalty),2) AS total_penalty,
       ROUND(SUM(p.paid_amount),2) AS total_paid
FROM loans l
LEFT JOIN loan_payments p ON l.loan_id=p.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_type, l.loan_status
HAVING SUM(p.days_late > 0) > 0
    OR SUM(p.status='Missed') > 0
ORDER BY late_payment_count DESC, total_penalty DESC;

-- Q5. Payment status and payment method
SELECT status, payment_method,
       COUNT(*) AS payments,
       ROUND(SUM(paid_amount),2) AS total_paid,
       ROUND(SUM(penalty),2) AS total_penalty,
       ROUND(AVG(days_late),2) AS avg_days_late
FROM loan_payments
GROUP BY status, payment_method
ORDER BY payments DESC;

-- Q6. Repayment performance by loan type
SELECT l.loan_type,
       COUNT(DISTINCT l.loan_id) AS loans,
       COUNT(p.payment_id) AS payments,
       SUM(p.status='Paid') AS paid_payments,
       SUM(p.status='Late') AS late_payments,
       SUM(p.status='Missed') AS missed_payments,
       ROUND(100 * SUM(p.status='Paid') / NULLIF(COUNT(p.payment_id),0),2) AS paid_rate_pct,
       ROUND(AVG(p.days_late),2) AS avg_days_late
FROM loans l
LEFT JOIN loan_payments p ON l.loan_id=p.loan_id
GROUP BY l.loan_type
ORDER BY paid_rate_pct DESC;

-- Q7. Loan performance by branch
SELECT b.branch_id, b.branch_name, b.region,
       COUNT(l.loan_id) AS loans,
       ROUND(SUM(l.principal_amount),2) AS principal,
       ROUND(SUM(l.outstanding_balance),2) AS outstanding,
       SUM(l.loan_status='Defaulted') AS defaulted_loans,
       SUM(l.loan_status='In Arrears') AS arrears_loans
FROM branches b
LEFT JOIN loans l ON b.branch_id=l.branch_id
GROUP BY b.branch_id, b.branch_name, b.region
ORDER BY outstanding DESC;

-- Q8. Use dataset's latest transaction date for maturity status
SELECT
    CASE
        WHEN maturity_date < @as_of_date THEN 'Matured'
        WHEN maturity_date = @as_of_date THEN 'Matures Today'
        ELSE 'Not Yet Matured'
    END AS maturity_bucket,
    COUNT(*) AS loans,
    ROUND(SUM(outstanding_balance),2) AS outstanding_balance
FROM loans
GROUP BY maturity_bucket
ORDER BY loans DESC;

-- 4.5 Understand Card Usage and Product Engagement
-- Q1. Card portfolio by type
SELECT card_type,
       COUNT(*) AS cards,
       SUM(is_active='Yes') AS active_cards,
       ROUND(AVG(credit_limit),2) AS avg_credit_limit,
       ROUND(AVG(outstanding_balance),2) AS avg_outstanding,
       ROUND(SUM(reward_points),0) AS total_reward_points
FROM cards
GROUP BY card_type
ORDER BY cards DESC;


-- Q2. Card network distribution
SELECT network, card_type,
       COUNT(*) AS cards,
       SUM(is_active='Yes') AS active_cards,
       ROUND(SUM(outstanding_balance),2) AS outstanding_balance
FROM cards
GROUP BY network, card_type
ORDER BY cards DESC;

--  Q3. Credit utilization for credit cards
SELECT card_id, account_id, network,
       credit_limit, outstanding_balance,
       ROUND(100 * outstanding_balance / NULLIF(credit_limit,0),2) AS utilization_pct
FROM cards
WHERE card_type='Credit'
ORDER BY utilization_pct DESC;

-- Q4. Customers with multiple banking products
WITH product_counts AS (
    SELECT c.customer_id,
           COUNT(DISTINCT a.account_id) AS account_count,
           COUNT(DISTINCT card.card_id) AS card_count,
           COUNT(DISTINCT l.loan_id) AS loan_count
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN cards card ON a.account_id=card.account_id
    LEFT JOIN loans l ON c.customer_id=l.customer_id
    GROUP BY c.customer_id
)
SELECT *,
       (account_count + card_count + loan_count) AS total_product_relationships
FROM product_counts
WHERE account_count > 0 AND (card_count > 0 OR loan_count > 0)
ORDER BY total_product_relationships DESC;

-- Q5. Product penetration by customer segment
WITH customer_products AS (
    SELECT c.customer_id, c.segment,
           COUNT(DISTINCT a.account_id) AS accounts,
           COUNT(DISTINCT card.card_id) AS cards,
           COUNT(DISTINCT l.loan_id) AS loans
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN cards card ON a.account_id=card.account_id
    LEFT JOIN loans l ON c.customer_id=l.customer_id
    GROUP BY c.customer_id, c.segment
)
SELECT segment,
       COUNT(*) AS customers,
       SUM(accounts > 0) AS customers_with_accounts,
       SUM(cards > 0) AS customers_with_cards,
       SUM(loans > 0) AS customers_with_loans,
       ROUND(100 * AVG(accounts > 0),2) AS account_penetration_pct,
       ROUND(100 * AVG(cards > 0),2) AS card_penetration_pct,
       ROUND(100 * AVG(loans > 0),2) AS loan_penetration_pct
FROM customer_products
GROUP BY segment
ORDER BY customers DESC;

-- Q6. Cards linked to accounts and branches
SELECT b.branch_name,
       a.account_type,
       card.card_type,
       card.network,
       COUNT(card.card_id) AS cards,
       SUM(card.is_active='Yes') AS active_cards
FROM branches b
JOIN accounts a ON b.branch_id=a.branch_id
JOIN cards card ON a.account_id=card.account_id
GROUP BY b.branch_name, a.account_type, card.card_type, card.network
ORDER BY cards DESC;


-- Q7. Expired cards using the guideline's dataset-based "today"
SELECT card_type, network,
       COUNT(*) AS expired_cards,
       SUM(is_active='Yes') AS still_marked_active
FROM cards
WHERE expiry_date < @as_of_date
GROUP BY card_type, network
ORDER BY expired_cards DESC;

--  The final Outcome/ Result of project
-- Customer Management

-- If one customer segment represents a large proportion of the customer base:

-- Management can further analyze product adoption and transaction behavior within this customer segment to understand its banking needs.

-- Branch Management

-- If account activity is concentrated in certain branches:

-- Management can investigate the factors driving higher account activity and compare staffing, customer mix and transaction volumes across branches.

-- Transaction Management

-- If certain channels dominate:

-- The bank can monitor transaction volumes and operational performance across the most-used channels.

-- Loan Management

-- If certain loan categories have high outstanding balances:

-- Management can examine repayment behavior, delinquency patterns and portfolio exposure within those loan categories.

-- Card Engagement

-- If card usage is concentrated in particular card types:

-- Management can examine the relationship between card type, usage, credit limits, outstanding balances and reward engagement.

-- Cross-Selling

-- If many customers have accounts but no cards or loans:

-- The bank can analyze product eligibility and customer behavior to understand opportunities for broader product adoption.

-- Final Project Conclusion

-- This project demonstrated an end-to-end approach to retail banking data analysis using MySQL. 
-- I started by understanding the business problem and the relationships between customers, accounts,
--  branches, transactions, loans, loan payments and cards. I then designed and validated the relational database, 
--  imported the available data and performed exploratory analysis.
-- Using SQL, I analyzed customer profiles, account usage, branch activity, transaction patterns, loan performance, 
-- repayment behavior, card usage and multi-product engagement. The analysis helped transform raw banking data into structured
--  business information that can be used to understand customer relationships, operational activity and financial product usage.
-- A key part of the analysis was translating business requirements into measurable analytical questions and selecting the appropriate tables, 
-- joins, aggregations and KPIs to answer them. I also considered data-quality issues such as duplicate records, NULL values and double 
-- counting when joining multiple one-to-many relationships.
-- Overall, the project demonstrates the complete Data Analyst workflow: understanding the business problem, 
-- understanding the data model, building the database, validating data, writing SQL queries, analyzing results, 
-- identifying patterns and communicating business insights.