-- Location: supabase/migrations/20250720170000_add_image_urls_column.sql
-- Fix missing 'image_urls' column causing PGRST204 error

-- Add the missing image_urls column to products table
ALTER TABLE public.products 
ADD COLUMN image_urls TEXT[];

-- Create index for better performance on image_urls queries
CREATE INDEX idx_products_image_urls ON public.products USING GIN (image_urls);

-- Migrate existing data from 'images' column to 'image_urls' if needed
UPDATE public.products 
SET image_urls = images 
WHERE images IS NOT NULL AND image_urls IS NULL;

-- Add comment for clarity
COMMENT ON COLUMN public.products.image_urls IS 'Array of image URLs for product gallery';