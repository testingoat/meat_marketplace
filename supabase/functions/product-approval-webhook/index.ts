import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-api-key',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify API key
    const apiKey = req.headers.get('x-api-key')
    const expectedApiKey = Deno.env.get('WEBHOOK_API_KEY')
    
    if (!apiKey || apiKey !== expectedApiKey) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse request body
    const { 
      product_id, 
      seller_id, 
      product_type, 
      approval_status, 
      rejection_reason, 
      updated_at 
    } = await req.json()

    // Validate required fields
    if (!product_id || !seller_id || !approval_status) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Update product approval status
    const { error: productError } = await supabase
      .from('products')
      .update({
        is_approved: approval_status === 'approved',
        updated_at: updated_at || new Date().toISOString()
      })
      .eq('id', product_id)
      .eq('seller_id', seller_id)

    if (productError) {
      console.error('Product update error:', productError)
      return new Response(
        JSON.stringify({ error: 'Failed to update product' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create or update product approval record
    const { error: approvalError } = await supabase
      .from('product_approvals')
      .upsert({
        meat_product_id: product_id,
        approval_status: approval_status,
        rejection_reason: approval_status === 'rejected' ? rejection_reason : null,
        updated_at: updated_at || new Date().toISOString()
      }, {
        onConflict: 'meat_product_id'
      })

    if (approvalError) {
      console.error('Approval record error:', approvalError)
      // Don't fail the webhook for this non-critical operation
    }

    // Create notification for seller
    const notificationTitle = approval_status === 'approved' 
      ? 'Product Approved' 
      : 'Product Rejected'
    
    const notificationMessage = approval_status === 'approved'
      ? 'Your product has been approved and is now live!'
      : `Your product was rejected. Reason: ${rejection_reason || 'No reason provided'}`

    const { error: notificationError } = await supabase
      .from('notifications')
      .insert({
        user_id: seller_id,
        title: notificationTitle,
        message: notificationMessage,
        type: 'general',
        data: {
          product_id,
          approval_status,
          rejection_reason
        }
      })

    if (notificationError) {
      console.error('Notification error:', notificationError)
      // Don't fail the webhook for this non-critical operation
    }

    // Log the webhook event
    const { error: logError } = await supabase
      .from('odoo_sync_logs')
      .insert({
        operation_type: 'webhook',
        entity_type: 'product',
        local_id: product_id,
        status: 'success',
        request_payload: {
          product_id,
          seller_id,
          product_type,
          approval_status,
          rejection_reason
        }
      })

    if (logError) {
      console.error('Log error:', logError)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Product approval processed successfully',
        product_id,
        approval_status
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})