-- Location: supabase/migrations/20250720160000_add_document_urls_column.sql
-- Add missing document_urls column to products table to fix PostgrestException

-- Add the missing document_urls column to products table
ALTER TABLE public.products
ADD COLUMN document_urls TEXT[];

-- Create index for the new column
CREATE INDEX idx_products_document_urls ON public.products USING GIN(document_urls);

-- Update existing products to copy documents to document_urls for backwards compatibility
UPDATE public.products 
SET document_urls = documents 
WHERE documents IS NOT NULL;

-- Add comment for clarity
COMMENT ON COLUMN public.products.document_urls IS 'Array of document URLs for product certificates and documentation';