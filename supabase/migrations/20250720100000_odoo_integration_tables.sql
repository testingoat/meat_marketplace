-- Odoo Integration Tables Migration
-- This migration adds tables to support Odoo ERP integration

-- Create webhook logs table to track webhook events from Odoo
CREATE TABLE public.webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_type TEXT NOT NULL,
    action TEXT NOT NULL,
    record_id INTEGER,
    success BOOLEAN DEFAULT false,
    message TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create sync status table to track synchronization state
CREATE TABLE public.sync_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL, -- 'product', 'order', 'customer'
    entity_id TEXT NOT NULL, -- Local entity ID
    odoo_id INTEGER, -- Corresponding Odoo record ID
    last_sync_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sync_direction TEXT DEFAULT 'bidirectional', -- 'app_to_odoo', 'odoo_to_app', 'bidirectional'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entity_type, entity_id)
);

-- Add Odoo-related columns to existing products table
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS odoo_id INTEGER;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'pending';

-- Add Odoo-related columns to existing orders table  
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS odoo_id INTEGER;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'pending';

-- Add indexes for better performance
CREATE INDEX idx_webhook_logs_type_created ON public.webhook_logs(webhook_type, created_at);
CREATE INDEX idx_webhook_logs_success ON public.webhook_logs(success, created_at);
CREATE INDEX idx_sync_status_entity ON public.sync_status(entity_type, entity_id);
CREATE INDEX idx_sync_status_odoo_id ON public.sync_status(odoo_id);
CREATE INDEX idx_products_odoo_id ON public.products(odoo_id) WHERE odoo_id IS NOT NULL;
CREATE INDEX idx_products_sync_status ON public.products(sync_status);
CREATE INDEX idx_orders_odoo_id ON public.orders(odoo_id) WHERE odoo_id IS NOT NULL;
CREATE INDEX idx_orders_sync_status ON public.orders(sync_status);

-- Enable RLS on new tables
ALTER TABLE public.webhook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_status ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for webhook_logs (admin access only)
CREATE POLICY "admin_webhook_logs_access" 
ON public.webhook_logs FOR ALL 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Create RLS policies for sync_status (admin and system access)
CREATE POLICY "admin_sync_status_access" 
ON public.sync_status FOR ALL 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'seller')
    )
);

-- Create helper function to update sync status
CREATE OR REPLACE FUNCTION public.update_sync_status(
    p_entity_type TEXT,
    p_entity_id TEXT,
    p_odoo_id INTEGER DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.sync_status (entity_type, entity_id, odoo_id, last_sync_at)
    VALUES (p_entity_type, p_entity_id, p_odoo_id, CURRENT_TIMESTAMP)
    ON CONFLICT (entity_type, entity_id) 
    DO UPDATE SET 
        odoo_id = COALESCE(EXCLUDED.odoo_id, sync_status.odoo_id),
        last_sync_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;

-- Create function to get pending sync items
CREATE OR REPLACE FUNCTION public.get_pending_sync_items(p_entity_type TEXT DEFAULT NULL)
RETURNS TABLE(
    entity_type TEXT,
    entity_id TEXT,
    entity_data JSONB,
    last_modified TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Return products that need syncing
    IF p_entity_type IS NULL OR p_entity_type = 'product' THEN
        RETURN QUERY
        SELECT 
            'product'::TEXT,
            p.id::TEXT,
            to_jsonb(p) - 'created_at' - 'updated_at',
            p.updated_at
        FROM public.products p
        LEFT JOIN public.sync_status ss ON ss.entity_type = 'product' AND ss.entity_id = p.id
        WHERE p.sync_status = 'pending' 
           OR ss.last_sync_at IS NULL 
           OR p.updated_at > ss.last_sync_at;
    END IF;

    -- Return orders that need syncing
    IF p_entity_type IS NULL OR p_entity_type = 'order' THEN
        RETURN QUERY
        SELECT 
            'order'::TEXT,
            o.id::TEXT,
            to_jsonb(o) - 'created_at' - 'updated_at',
            o.updated_at
        FROM public.orders o
        LEFT JOIN public.sync_status ss ON ss.entity_type = 'order' AND ss.entity_id = o.id
        WHERE o.sync_status = 'pending' 
           OR ss.last_sync_at IS NULL 
           OR o.updated_at > ss.last_sync_at;
    END IF;
END;
$$;

-- Create trigger function to automatically update sync status
CREATE OR REPLACE FUNCTION public.trigger_sync_status_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update sync status when products or orders are modified
    IF TG_TABLE_NAME = 'products' THEN
        NEW.sync_status = 'pending';
        NEW.last_synced_at = NULL;
    ELSIF TG_TABLE_NAME = 'orders' THEN
        NEW.sync_status = 'pending';
        NEW.last_synced_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create triggers to automatically mark items as needing sync
CREATE TRIGGER products_sync_trigger
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION public.trigger_sync_status_update();

CREATE TRIGGER orders_sync_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION public.trigger_sync_status_update();

-- Create function to clean up old webhook logs (retain last 30 days)
CREATE OR REPLACE FUNCTION public.cleanup_webhook_logs()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.webhook_logs 
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '30 days');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- Add sample webhook log entry
INSERT INTO public.webhook_logs (webhook_type, action, record_id, success, message, raw_data)
VALUES (
    'system',
    'migration',
    0,
    true,
    'Odoo integration tables created successfully',
    '{"migration": "20250720100000_odoo_integration_tables", "timestamp": "2025-07-20T10:00:00Z"}'::jsonb
);

COMMENT ON TABLE public.webhook_logs IS 'Logs all webhook events received from Odoo ERP';
COMMENT ON TABLE public.sync_status IS 'Tracks synchronization status between local entities and Odoo records';
COMMENT ON FUNCTION public.update_sync_status(TEXT, TEXT, INTEGER) IS 'Updates or creates sync status record for an entity';
COMMENT ON FUNCTION public.get_pending_sync_items(TEXT) IS 'Returns entities that need to be synchronized with Odoo';
COMMENT ON FUNCTION public.cleanup_webhook_logs() IS 'Removes webhook logs older than 30 days';