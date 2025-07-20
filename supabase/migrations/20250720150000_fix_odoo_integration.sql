-- Location: supabase/migrations/20250720150000_fix_odoo_integration.sql
-- Fix enum value mismatch and enhance Odoo integration

-- 1. Fix product_category enum to include 'meat' value
ALTER TYPE public.product_category ADD VALUE 'meat';

-- 2. Add Odoo integration tables
CREATE TABLE public.odoo_sync_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type TEXT NOT NULL, -- 'sync', 'create', 'update', 'delete'
    entity_type TEXT NOT NULL, -- 'product', 'user', 'order'
    local_id UUID,
    odoo_id INTEGER,
    status TEXT NOT NULL, -- 'success', 'error', 'pending'
    error_message TEXT,
    request_payload JSONB,
    response_payload JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.odoo_product_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    odoo_product_id INTEGER NOT NULL,
    sync_status TEXT DEFAULT 'synced', -- 'synced', 'pending', 'error'
    last_synced_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.odoo_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    server_url TEXT NOT NULL,
    database_name TEXT NOT NULL,
    username TEXT NOT NULL,
    fields_to_sync TEXT[] DEFAULT ARRAY['name', 'list_price', 'uom_id'],
    sync_enabled BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Add indexes for performance
CREATE INDEX idx_odoo_sync_logs_entity ON public.odoo_sync_logs(entity_type, local_id);
CREATE INDEX idx_odoo_sync_logs_status ON public.odoo_sync_logs(status);
CREATE INDEX idx_odoo_product_mappings_local_id ON public.odoo_product_mappings(local_product_id);
CREATE INDEX idx_odoo_product_mappings_odoo_id ON public.odoo_product_mappings(odoo_product_id);
CREATE INDEX idx_odoo_configurations_user_id ON public.odoo_configurations(user_id);

-- 4. Enable RLS for new tables
ALTER TABLE public.odoo_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odoo_product_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odoo_configurations ENABLE ROW LEVEL SECURITY;

-- 5. Helper functions for Odoo access control
CREATE OR REPLACE FUNCTION public.can_access_odoo_logs(log_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.odoo_sync_logs osl
    WHERE osl.id = log_id AND (
        public.is_admin(auth.uid()) OR
        EXISTS (
            SELECT 1 FROM public.products p
            WHERE p.id = osl.local_id AND p.seller_id = auth.uid()
        )
    )
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_odoo_mappings(mapping_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.odoo_product_mappings opm
    JOIN public.products p ON opm.local_product_id = p.id
    WHERE opm.id = mapping_id AND (
        p.seller_id = auth.uid() OR
        public.is_admin(auth.uid())
    )
)
$$;

-- 6. RLS Policies for Odoo tables
CREATE POLICY "users_access_own_odoo_logs" ON public.odoo_sync_logs FOR ALL
USING (public.can_access_odoo_logs(id))
WITH CHECK (public.can_access_odoo_logs(id));

CREATE POLICY "users_access_own_product_mappings" ON public.odoo_product_mappings FOR ALL
USING (public.can_access_odoo_mappings(id))
WITH CHECK (public.can_access_odoo_mappings(id));

CREATE POLICY "users_manage_own_odoo_config" ON public.odoo_configurations FOR ALL
USING (user_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (user_id = auth.uid() OR public.is_admin(auth.uid()));

-- 7. Function to log Odoo operations
CREATE OR REPLACE FUNCTION public.log_odoo_operation(
    p_operation_type TEXT,
    p_entity_type TEXT,
    p_local_id UUID DEFAULT NULL,
    p_odoo_id INTEGER DEFAULT NULL,
    p_status TEXT DEFAULT 'pending',
    p_error_message TEXT DEFAULT NULL,
    p_request_payload JSONB DEFAULT NULL,
    p_response_payload JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO public.odoo_sync_logs (
        operation_type, entity_type, local_id, odoo_id, status,
        error_message, request_payload, response_payload
    ) VALUES (
        p_operation_type, p_entity_type, p_local_id, p_odoo_id, p_status,
        p_error_message, p_request_payload, p_response_payload
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$;

-- 8. Function to update product mapping
CREATE OR REPLACE FUNCTION public.upsert_odoo_product_mapping(
    p_local_product_id UUID,
    p_odoo_product_id INTEGER,
    p_sync_status TEXT DEFAULT 'synced'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mapping_id UUID;
BEGIN
    INSERT INTO public.odoo_product_mappings (
        local_product_id, odoo_product_id, sync_status, last_synced_at
    ) VALUES (
        p_local_product_id, p_odoo_product_id, p_sync_status, CURRENT_TIMESTAMP
    )
    ON CONFLICT (local_product_id) DO UPDATE SET
        odoo_product_id = EXCLUDED.odoo_product_id,
        sync_status = EXCLUDED.sync_status,
        last_synced_at = CURRENT_TIMESTAMP
    RETURNING id INTO mapping_id;
    
    RETURN mapping_id;
END;
$$;

-- 9. Trigger to update product sync status when products change
CREATE OR REPLACE FUNCTION public.mark_product_for_sync()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Mark existing mapping as needing sync
    UPDATE public.odoo_product_mappings 
    SET sync_status = 'pending'
    WHERE local_product_id = NEW.id;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER product_sync_trigger
    AFTER UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.mark_product_for_sync();