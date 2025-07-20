import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const webhookData = await req.json();
    console.log('Received webhook:', webhookData);

    // Extract webhook information
    const { model, action, record_id, data } = webhookData;

    if (!model || !action || !record_id) {
      throw new Error('Missing required webhook parameters: model, action, record_id');
    }

    // Route webhook based on model type
    let result;
    switch (model) {
      case 'product.product':
        result = await handleProductWebhook(supabase, action, record_id, data);
        break;
      case 'sale.order':
        result = await handleOrderWebhook(supabase, action, record_id, data);
        break;
      case 'res.partner':
        result = await handleCustomerWebhook(supabase, action, record_id, data);
        break;
      case 'stock.quant':
        result = await handleInventoryWebhook(supabase, action, record_id, data);
        break;
      default:
        console.log(`Unhandled webhook model: ${model}`);
        result = { success: false, message: `Unhandled model: ${model}` };
    }

    // Log webhook processing result
    await logWebhookEvent(supabase, {
      model,
      action,
      record_id,
      success: result.success,
      message: result.message,
      data: webhookData
    });

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Webhook processing error:', error);
    
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Handle product webhooks
async function handleProductWebhook(supabase: any, action: string, recordId: number, data: any) {
  try {
    console.log(`Processing product ${action} for record ${recordId}`);

    switch (action) {
      case 'create':
      case 'write':
        // Update or create product in local database
        const productData = {
          name: data.name,
          description: data.description,
          price: data.list_price || data.price,
          category: data.categ_name || 'Other',
          stock_quantity: Math.floor(data.qty_available || 0),
          is_available: data.active || true,
          updated_at: new Date().toIso8601String()
        };

        // Find existing product by Odoo reference
        const { data: existingProduct } = await supabase
          .from('products')
          .select('id')
          .eq('name', data.name)
          .single();

        if (existingProduct) {
          // Update existing product
          await supabase
            .from('products')
            .update(productData)
            .eq('id', existingProduct.id);
        } else {
          // Create new product if it doesn't exist
          productData.id = crypto.randomUUID();
          productData.seller_id = 'odoo-sync';
          productData.unit = 'kg';
          productData.minimum_order_quantity = 1;
          productData.images = [];
          productData.documents = [];
          productData.is_approved = true;
          productData.created_at = new Date().toIso8601String();

          await supabase
            .from('products')
            .insert([productData]);
        }

        return { success: true, message: `Product ${action} processed successfully` };

      case 'unlink':
        // Soft delete product
        await supabase
          .from('products')
          .update({ is_available: false, updated_at: new Date().toIso8601String() })
          .eq('name', data.name);

        return { success: true, message: 'Product deleted successfully' };

      default:
        return { success: false, message: `Unhandled product action: ${action}` };
    }
  } catch (error) {
    console.error('Product webhook error:', error);
    return { success: false, message: error.message };
  }
}

// Handle order webhooks
async function handleOrderWebhook(supabase: any, action: string, recordId: number, data: any) {
  try {
    console.log(`Processing order ${action} for record ${recordId}`);

    switch (action) {
      case 'create':
        // Create new order from Odoo
        const orderId = crypto.randomUUID();
        const orderData = {
          id: orderId,
          order_number: data.name || `ODO-${recordId}`,
          buyer_id: 'odoo-customer',
          seller_id: 'odoo-sync',
          total_amount: data.amount_total || 0,
          status: mapOdooStatusToApp(data.state),
          delivery_address: data.partner_shipping_address || 'Not specified',
          customer_phone: data.partner_phone,
          notes: `Odoo Order #${data.name}`,
          created_at: new Date().toIso8601String(),
          updated_at: new Date().toIso8601String()
        };

        await supabase
          .from('orders')
          .insert([orderData]);

        // Create order items if provided
        if (data.order_line && Array.isArray(data.order_line)) {
          const orderItems = data.order_line.map((line: any) => ({
            id: crypto.randomUUID(),
            order_id: orderId,
            product_id: 'odoo-product',
            quantity: Math.floor(line.product_uom_qty || 1),
            unit_price: line.price_unit || 0,
            total_price: line.price_subtotal || 0,
            created_at: new Date().toIso8601String()
          }));

          await supabase
            .from('order_items')
            .insert(orderItems);
        }

        return { success: true, message: 'Order created successfully' };

      case 'write':
        // Update existing order
        const updateData = {
          status: mapOdooStatusToApp(data.state),
          total_amount: data.amount_total,
          updated_at: new Date().toIso8601String()
        };

        await supabase
          .from('orders')
          .update(updateData)
          .eq('order_number', data.name);

        return { success: true, message: 'Order updated successfully' };

      case 'action_confirm':
        // Order confirmed in Odoo
        await supabase
          .from('orders')
          .update({ 
            status: 'confirmed', 
            updated_at: new Date().toIso8601String() 
          })
          .eq('order_number', data.name);

        return { success: true, message: 'Order confirmed' };

      case 'action_done':
        // Order completed in Odoo
        await supabase
          .from('orders')
          .update({ 
            status: 'delivered', 
            updated_at: new Date().toIso8601String() 
          })
          .eq('order_number', data.name);

        return { success: true, message: 'Order completed' };

      case 'action_cancel':
        // Order cancelled in Odoo
        await supabase
          .from('orders')
          .update({ 
            status: 'cancelled', 
            updated_at: new Date().toIso8601String() 
          })
          .eq('order_number', data.name);

        return { success: true, message: 'Order cancelled' };

      default:
        return { success: false, message: `Unhandled order action: ${action}` };
    }
  } catch (error) {
    console.error('Order webhook error:', error);
    return { success: false, message: error.message };
  }
}

// Handle customer webhooks
async function handleCustomerWebhook(supabase: any, action: string, recordId: number, data: any) {
  try {
    console.log(`Processing customer ${action} for record ${recordId}`);

    // Customer webhooks are mainly for logging purposes
    // as customer data is usually created during order processing
    return { success: true, message: `Customer ${action} acknowledged` };
  } catch (error) {
    console.error('Customer webhook error:', error);
    return { success: false, message: error.message };
  }
}

// Handle inventory webhooks
async function handleInventoryWebhook(supabase: any, action: string, recordId: number, data: any) {
  try {
    console.log(`Processing inventory ${action} for record ${recordId}`);

    if (data.product_id && data.quantity !== undefined) {
      // Update product inventory
      await supabase
        .from('products')
        .update({ 
          stock_quantity: Math.floor(data.quantity),
          updated_at: new Date().toIso8601String()
        })
        .eq('name', data.product_name);
    }

    return { success: true, message: 'Inventory updated successfully' };
  } catch (error) {
    console.error('Inventory webhook error:', error);
    return { success: false, message: error.message };
  }
}

// Log webhook events
async function logWebhookEvent(supabase: any, eventData: any) {
  try {
    const logEntry = {
      id: crypto.randomUUID(),
      webhook_type: eventData.model,
      action: eventData.action,
      record_id: eventData.record_id,
      success: eventData.success,
      message: eventData.message,
      raw_data: eventData.data,
      created_at: new Date().toIso8601String()
    };

    await supabase
      .from('webhook_logs')
      .insert([logEntry]);
  } catch (error) {
    console.error('Failed to log webhook event:', error);
  }
}

// Map Odoo order states to app status
function mapOdooStatusToApp(odooState: string): string {
  const statusMap: { [key: string]: string } = {
    'draft': 'pending',
    'sent': 'pending',
    'sale': 'confirmed',
    'done': 'delivered',
    'cancel': 'cancelled'
  };

  return statusMap[odooState] || 'pending';
}