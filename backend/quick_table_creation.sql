-- =====================================================
-- QUICK TABLE CREATION QUERIES
-- =====================================================
-- Copy and paste these queries one by one into Supabase SQL Editor

-- =====================================================
-- 1. CREATE SUBSCRIPTION PLANS TABLE
-- =====================================================
CREATE TABLE subscription_plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    credits INTEGER NOT NULL,
    max_meal_price DECIMAL(10,2) NOT NULL,
    discount_percentage INTEGER DEFAULT 0,
    duration_days INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. CREATE USER SUBSCRIPTIONS TABLE
-- =====================================================
CREATE TABLE user_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    plan_id INTEGER REFERENCES subscription_plans(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    remaining_credits INTEGER NOT NULL,
    total_credits INTEGER NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. CREATE CREDIT TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE credit_transactions (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    order_id INTEGER REFERENCES orders(id),
    credits_used INTEGER NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. CREATE SUBSCRIPTION PAYMENTS TABLE
-- =====================================================
CREATE TABLE subscription_payments (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_status VARCHAR(20) DEFAULT 'pending',
    razorpay_payment_id VARCHAR(255),
    razorpay_order_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 5. INSERT DEFAULT SUBSCRIPTION PLANS
-- =====================================================
INSERT INTO subscription_plans (name, description, price, credits, max_meal_price, discount_percentage, duration_days) VALUES
('Basic Plan', 'Perfect for occasional diners', 999.00, 10, 150.00, 0, 30),
('Premium Plan', 'Great value for regular customers', 1999.00, 25, 200.00, 10, 30),
('Elite Plan', 'Best value for frequent diners', 2999.00, 40, 300.00, 15, 30);

-- =====================================================
-- 6. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_end_date ON user_subscriptions(end_date);
CREATE INDEX idx_credit_transactions_subscription_id ON credit_transactions(subscription_id);
CREATE INDEX idx_credit_transactions_order_id ON credit_transactions(order_id);
CREATE INDEX idx_subscription_payments_subscription_id ON subscription_payments(subscription_id);
CREATE INDEX idx_subscription_payments_status ON subscription_payments(payment_status);

-- =====================================================
-- 7. VERIFICATION QUERY
-- =====================================================
-- Run this to verify everything was created successfully
SELECT 'Tables created successfully!' as status,
       (SELECT COUNT(*) FROM subscription_plans) as plans_count,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('subscription_plans', 'user_subscriptions', 'credit_transactions', 'subscription_payments')) as tables_count;
