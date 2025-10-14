-- Add completed_at column to reservations table
-- This column will store the timestamp when a reservation is marked as completed

ALTER TABLE public.reservations 
ADD COLUMN completed_at timestamp with time zone NULL;

-- Add a comment to explain the column
COMMENT ON COLUMN public.reservations.completed_at IS 'Timestamp when the reservation was marked as completed by the customer';
