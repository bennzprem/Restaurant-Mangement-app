-- Create user_addresses table
CREATE TABLE IF NOT EXISTS user_addresses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    house_no VARCHAR(255) NOT NULL,
    area VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    pincode VARCHAR(20) NOT NULL,
    contact_name VARCHAR(255),
    contact_phone VARCHAR(20),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_default ON user_addresses(user_id, is_default);

-- Enable Row Level Security
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own addresses" ON user_addresses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses" ON user_addresses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses" ON user_addresses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses" ON user_addresses
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_user_addresses_updated_at 
    BEFORE UPDATE ON user_addresses 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

