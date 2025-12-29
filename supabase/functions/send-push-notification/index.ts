// Supabase Edge Function to send FCM push notifications using V1 API
// This function is called from database triggers or other functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

// Get environment variables
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

interface NotificationPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

// Get OAuth2 access token for FCM V1 API
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  // Parse PEM private key
  const privateKeyPem = serviceAccount.private_key
    .replace(/\\n/g, "\n")
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  
  const privateKeyDer = Uint8Array.from(atob(privateKeyPem), c => c.charCodeAt(0));
  
  // Import the private key
  const key = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Create JWT
  const now = getNumericDate(new Date());
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    },
    key
  );

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    if (!FCM_SERVICE_ACCOUNT_JSON) {
      throw new Error("FCM_SERVICE_ACCOUNT_JSON environment variable is not set");
    }

    const payload: NotificationPayload = await req.json();
    const { token, title, body, data = {} } = payload;

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: token, title, body" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Parse service account JSON
    const serviceAccount: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    
    if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
      throw new Error("Invalid service account JSON. Missing required fields.");
    }

    // Get OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount);

    // Prepare FCM V1 API message
    const fcmV1Url = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    
    const fcmMessage = {
      message: {
        token: token,
        notification: {
          title,
          body,
        },
        data: Object.fromEntries(
          Object.entries(data).map(([key, value]) => [key, String(value)])
        ),
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    // Send to FCM V1 API
    const fcmResponse = await fetch(fcmV1Url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmMessage),
    });

    const fcmResult = await fcmResponse.json();

    if (!fcmResponse.ok) {
      console.error("FCM V1 Error:", fcmResult);
      return new Response(
        JSON.stringify({ error: "Failed to send notification", details: fcmResult }),
        { status: fcmResponse.status, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: fcmResult.name }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

