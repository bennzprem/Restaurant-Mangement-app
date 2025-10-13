-- Add pickup_code column to orders table
-- Run this in your Supabase SQL editor

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS pickup_code VARCHAR(4);

-- Add a comment to describe the column
COMMENT ON COLUMN orders.pickup_code IS '4-digit pickup code for takeaway orders';

-- Create an index for faster lookups (optional)
CREATE INDEX IF NOT EXISTS idx_orders_pickup_code ON orders(pickup_code);

