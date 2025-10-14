-- =====================================================
-- SUBSCRIPTION SYSTEM DATABASE SCHEMA
-- =====================================================
-- Run this script in your Supabase SQL Editor
-- This creates all necessary tables for the meal subscription system

-- =====================================================
-- 1. SUBSCRIPTION PLANS TABLE
-- =====================================================
-- Stores all available subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    credits INTEGER NOT NULL,
    max_meal_price DECIMAL(10,2) NOT NULL,
    discount_percentage INTEGER DEFAULT 0,
    duration_days INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 2. USER SUBSCRIPTIONS TABLE
-- =====================================================
-- Tracks user's active and past subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    plan_id INTEGER REFERENCES subscription_plans(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, expired, cancelled, paused
    remaining_credits INTEGER NOT NULL,
    total_credits INTEGER NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 3. CREDIT TRANSACTIONS TABLE
-- =====================================================
-- Logs all credit usage, refunds, and bonuses
CREATE TABLE IF NOT EXISTS credit_transactions (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    order_id INTEGER REFERENCES orders(id),
    credits_used INTEGER NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'used', 'refunded', 'bonus', 'purchased'
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 4. SUBSCRIPTION PAYMENTS TABLE
-- =====================================================
-- Tracks subscription payments and billing
CREATE TABLE IF NOT EXISTS subscription_payments (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50), -- 'razorpay', 'cash', 'card'
    payment_status VARCHAR(20) DEFAULT 'pending', -- pending, completed, failed, refunded
    razorpay_payment_id VARCHAR(255),
    razorpay_order_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_subscription_id ON credit_transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_order_id ON credit_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_subscription_id ON subscription_payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_status ON subscription_payments(payment_status);

-- =====================================================
-- INSERT DEFAULT SUBSCRIPTION PLANS
-- =====================================================
-- Insert the three subscription plans we defined in the UI
INSERT INTO subscription_plans (name, description, price, credits, max_meal_price, discount_percentage, duration_days) VALUES
('Basic Plan', 'Perfect for occasional diners', 999.00, 10, 150.00, 0, 30),
('Premium Plan', 'Great value for regular customers', 1999.00, 25, 200.00, 10, 30),
('Elite Plan', 'Best value for frequent diners', 2999.00, 40, 300.00, 15, 30)
ON CONFLICT DO NOTHING;

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================
-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply the trigger to relevant tables
CREATE TRIGGER update_subscription_plans_updated_at 
    BEFORE UPDATE ON subscription_plans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at 
    BEFORE UPDATE ON user_subscriptions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- Enable RLS on tables
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;

-- Policies for subscription_plans (public read access)
CREATE POLICY "Anyone can view subscription plans" ON subscription_plans
    FOR SELECT USING (true);

-- Policies for user_subscriptions (users can only see their own)
CREATE POLICY "Users can view their own subscriptions" ON user_subscriptions
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own subscriptions" ON user_subscriptions
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own subscriptions" ON user_subscriptions
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Policies for credit_transactions (users can only see their own)
CREATE POLICY "Users can view their own credit transactions" ON credit_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_subscriptions 
            WHERE user_subscriptions.id = credit_transactions.subscription_id 
            AND user_subscriptions.user_id = auth.uid()::text
        )
    );

-- Policies for subscription_payments (users can only see their own)
CREATE POLICY "Users can view their own subscription payments" ON subscription_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_subscriptions 
            WHERE user_subscriptions.id = subscription_payments.subscription_id 
            AND user_subscriptions.user_id = auth.uid()::text
        )
    );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these queries to verify everything was created correctly

-- Check if tables were created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('subscription_plans', 'user_subscriptions', 'credit_transactions', 'subscription_payments');

-- Check if subscription plans were inserted
SELECT * FROM subscription_plans ORDER BY price;

-- Check if indexes were created
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('subscription_plans', 'user_subscriptions', 'credit_transactions', 'subscription_payments');

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- If you see this message, the subscription system database setup is complete!
SELECT 'Subscription system database setup completed successfully!' as status;
