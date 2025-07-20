import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { odoo_endpoint, data, session_id } = await req.json()

    // Odoo server configuration
    const ODOO_URL = "https://goatgoat.xyz"
    const ODOO_DB = "staging"
    const ODOO_USERNAME = "admin"
    const ODOO_PASSWORD = "admin"

    let odooUrl = `${ODOO_URL}${odoo_endpoint}`
    let requestBody = data

    // Handle authentication endpoint
    if (odoo_endpoint === '/web/session/authenticate') {
      const authResponse = await fetch(odooUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          method: "call",
          params: {
            db: ODOO_DB,
            login: ODOO_USERNAME,
            password: ODOO_PASSWORD
          }
        })
      })

      const authData = await authResponse.json()
      
      if (authData.result && authData.result.uid) {
        // Extract session ID from cookies
        const cookies = authResponse.headers.get('set-cookie')
        let sessionId = null
        
        if (cookies) {
          const sessionMatch = cookies.match(/session_id=([^;]+)/)
          sessionId = sessionMatch ? sessionMatch[1] : null
        }

        return new Response(
          JSON.stringify({
            ...authData,
            result: {
              ...authData.result,
              session_id: sessionId
            }
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      return new Response(
        JSON.stringify(authData),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Handle other API calls with session
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    }

    if (session_id) {
      headers['Cookie'] = `session_id=${session_id}`
    }

    const response = await fetch(odooUrl, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(requestBody)
    })

    const responseData = await response.json()

    return new Response(
      JSON.stringify(responseData),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Odoo API proxy error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: { 
          message: `API proxy failed: ${error.message}`,
          type: 'proxy_error'
        } 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})