-- Location: supabase/migrations/20250720091431_meat_marketplace_schema.sql
-- Meat Marketplace Database Schema with Auth-Enabled Mode

-- 1. Extensions and Types
CREATE TYPE public.user_role AS ENUM ('admin', 'seller', 'buyer');
CREATE TYPE public.order_status AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE public.product_category AS ENUM ('chicken', 'mutton', 'fish', 'seafood', 'pork', 'beef', 'others');
CREATE TYPE public.product_unit AS ENUM ('kg', 'grams', 'pieces', 'dozen');
CREATE TYPE public.notification_type AS ENUM ('order', 'payment', 'inventory', 'general');

-- 2. User Profiles Table (Critical intermediary for auth relationships)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    role public.user_role DEFAULT 'buyer'::public.user_role,
    business_name TEXT,
    business_status TEXT DEFAULT 'active',
    profile_image_url TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Products Table
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category public.product_category NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    unit public.product_unit DEFAULT 'kg'::public.product_unit,
    stock_quantity INTEGER DEFAULT 0,
    minimum_order_quantity INTEGER DEFAULT 1,
    is_available BOOLEAN DEFAULT true,
    nutritional_info TEXT,
    preparation_instructions TEXT,
    storage_instructions TEXT,
    images TEXT[], -- Array of image URLs
    documents TEXT[], -- Array of document URLs (certificates, etc.)
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Orders Table
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    buyer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL,
    status public.order_status DEFAULT 'pending'::public.order_status,
    delivery_address TEXT NOT NULL,
    delivery_city TEXT,
    delivery_state TEXT,
    delivery_pincode TEXT,
    customer_phone TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Order Items Table
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Notifications Table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type public.notification_type DEFAULT 'general'::public.notification_type,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_products_seller_id ON public.products(seller_id);
CREATE INDEX idx_products_category ON public.products(category);
CREATE INDEX idx_products_is_available ON public.products(is_available);
CREATE INDEX idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX idx_orders_seller_id ON public.orders(seller_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);

-- 8. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 9. Helper Functions for RLS
CREATE OR REPLACE FUNCTION public.is_seller(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = user_uuid AND up.role = 'seller'
)
$$;

CREATE OR REPLACE FUNCTION public.is_admin(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = user_uuid AND up.role = 'admin'
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_product(product_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_uuid AND (
        p.is_available = true OR 
        p.seller_id = auth.uid() OR
        public.is_admin(auth.uid())
    )
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_order(order_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_uuid AND (
        o.buyer_id = auth.uid() OR
        o.seller_id = auth.uid() OR
        public.is_admin(auth.uid())
    )
)
$$;

-- 10. RLS Policies
-- User Profiles
CREATE POLICY "users_view_own_profile" ON public.user_profiles FOR SELECT
USING (auth.uid() = id OR public.is_admin(auth.uid()));

CREATE POLICY "users_update_own_profile" ON public.user_profiles FOR UPDATE
USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Products
CREATE POLICY "public_view_available_products" ON public.products FOR SELECT
USING (is_available = true AND is_approved = true);

CREATE POLICY "sellers_manage_own_products" ON public.products FOR ALL
USING (seller_id = auth.uid() OR public.is_admin(auth.uid()))
WITH CHECK (seller_id = auth.uid() OR public.is_admin(auth.uid()));

-- Orders
CREATE POLICY "users_access_own_orders" ON public.orders FOR ALL
USING (public.can_access_order(id))
WITH CHECK (public.can_access_order(id));

-- Order Items
CREATE POLICY "users_access_order_items" ON public.order_items FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_id AND public.can_access_order(o.id)
    )
);

-- Notifications
CREATE POLICY "users_view_own_notifications" ON public.notifications FOR ALL
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 11. Functions for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'buyer'::public.user_role)
  );
  RETURN NEW;
END;
$$;

-- 12. Trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. Function to generate order numbers
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    order_num TEXT;
    counter INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO counter FROM public.orders;
    order_num := 'ORD' || LPAD(counter::TEXT, 6, '0');
    RETURN order_num;
END;
$$;

-- 14. Complete Mock Data with Full Auth Users
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    seller1_uuid UUID := gen_random_uuid();
    seller2_uuid UUID := gen_random_uuid();
    buyer1_uuid UUID := gen_random_uuid();
    buyer2_uuid UUID := gen_random_uuid();
    product1_uuid UUID := gen_random_uuid();
    product2_uuid UUID := gen_random_uuid();
    product3_uuid UUID := gen_random_uuid();
    order1_uuid UUID := gen_random_uuid();
    order2_uuid UUID := gen_random_uuid();
BEGIN
    -- Create complete auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@meatmarket.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (seller1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'seller1@meatmarket.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Rajesh Kumar", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (seller2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'seller2@meatmarket.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Priya Sharma", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (buyer1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'buyer1@meatmarket.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Amit Patel", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (buyer2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'buyer2@meatmarket.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sunita Reddy", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create products
    INSERT INTO public.products (id, seller_id, name, description, category, price, unit, stock_quantity, is_available, is_approved, images) VALUES
        (product1_uuid, seller1_uuid, 'Fresh Chicken Breast', 'Premium quality chicken breast, perfect for grilling and cooking', 'chicken'::public.product_category, 400.00, 'kg'::public.product_unit, 50, true, true, 
         ARRAY['https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500']),
        (product2_uuid, seller1_uuid, 'Mutton Curry Cut', 'Fresh mutton cut perfect for curries and biryani', 'mutton'::public.product_category, 650.00, 'kg'::public.product_unit, 25, true, true,
         ARRAY['https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', 'https://images.unsplash.com/photo-1603048297172-c92544798d5a?w=500']),
        (product3_uuid, seller2_uuid, 'Fresh Fish Fillet', 'Daily fresh fish fillet, cleaned and ready to cook', 'fish'::public.product_category, 600.00, 'kg'::public.product_unit, 30, true, true,
         ARRAY['https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500', 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=500']);

    -- Create orders
    INSERT INTO public.orders (id, order_number, buyer_id, seller_id, total_amount, status, delivery_address, customer_phone) VALUES
        (order1_uuid, 'ORD000001', buyer1_uuid, seller1_uuid, 1450.00, 'pending'::public.order_status, '123 MG Road, Bangalore, Karnataka 560001', '+91 9876543210'),
        (order2_uuid, 'ORD000002', buyer2_uuid, seller2_uuid, 1800.00, 'processing'::public.order_status, '456 Brigade Road, Bangalore, Karnataka 560025', '+91 9876543211');

    -- Create order items
    INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
        (order1_uuid, product1_uuid, 2, 400.00, 800.00),
        (order1_uuid, product2_uuid, 1, 650.00, 650.00),
        (order2_uuid, product3_uuid, 3, 600.00, 1800.00);

    -- Create notifications
    INSERT INTO public.notifications (user_id, title, message, type) VALUES
        (seller1_uuid, 'New Order Received', 'New order received from Amit Patel - ₹1,450', 'order'::public.notification_type),
        (seller1_uuid, 'Low Stock Alert', 'Chicken Breast stock is running low (5 kg remaining)', 'inventory'::public.notification_type),
        (buyer1_uuid, 'Order Confirmed', 'Your order #ORD000001 has been confirmed by the seller', 'order'::public.notification_type);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 15. Cleanup function for test data
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs first
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@meatmarket.com';

    -- Delete in dependency order (children first, then auth.users last)
    DELETE FROM public.notifications WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.order_items WHERE order_id IN (SELECT id FROM public.orders WHERE buyer_id = ANY(auth_user_ids_to_delete) OR seller_id = ANY(auth_user_ids_to_delete));
    DELETE FROM public.orders WHERE buyer_id = ANY(auth_user_ids_to_delete) OR seller_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.products WHERE seller_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);

    -- Delete auth.users last (after all references are removed)
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;