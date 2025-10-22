import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function isValidRound(x: unknown): x is 1 | 2 | 3 {
  return x === 1 || x === 2 || x === 3;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
    const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");
    const GOOGLE_SERVICE_ACCOUNT_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
    const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
      return json({ error: "server not configured" }, 500);
    }

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });

    // TODO Phase 4: enforce admin role on caller

    const { round } = await req.json().catch(() => ({}));
    if (!isValidRound(round)) return json({ error: "invalid round (1|2|3)" }, 400);

    const { error: upErr } = await admin
      .from("current_round")
      .upsert({ id: 1, round, updated_at: new Date().toISOString() }, { onConflict: "id" });
    if (upErr) return json({ error: upErr.message }, 500);

    // Broadcast round.changed
    try {
      const channel = client.channel("round");
      await channel.subscribe(async (status) => {
        if (status === "SUBSCRIBED") {
          await channel.send({ type: "broadcast", event: "round.changed", payload: { round, ts: new Date().toISOString() } });
          await channel.unsubscribe();
        }
      });
      await new Promise((r) => setTimeout(r, 150));
    } catch (e) {
      console.warn("Realtime publish failed:", e);
    }

    // Optional push notification (generic)
    let pushSummary: { success: number; failure: number } | undefined;
    try {
      // Fetch tokens once
      const { data: tokens, error: tErr } = await admin
        .from("user_push_tokens")
        .select("token")
        .limit(5000);
      if (tErr) throw tErr;
      const tokenList = (tokens ?? []).map((t: any) => String(t.token)).filter(Boolean);

      if (tokenList.length > 0) {
        let success = 0;
        let failure = 0;

        if (FCM_SERVER_KEY) {
          // Legacy HTTP v1 (deprecated) multicast path
          const chunkSize = 500;
          for (let i = 0; i < tokenList.length; i += chunkSize) {
            const batch = tokenList.slice(i, i + chunkSize);
            const res = await fetch("https://fcm.googleapis.com/fcm/send", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `key=${FCM_SERVER_KEY}`,
              },
              body: JSON.stringify({
                registration_ids: batch,
                notification: {
                  title: `Round ${round} started`,
                  body: "Open Asteria to see your table",
                },
                data: { round: String(round) },
                priority: "high",
              }),
            });
            const body = await res.json().catch(() => ({}));
            if (typeof (body?.success) === "number") success += body.success;
            if (typeof (body?.failure) === "number") failure += body.failure;
          }
        } else if (GOOGLE_SERVICE_ACCOUNT_JSON && FIREBASE_PROJECT_ID) {
          // HTTP v1 per-token send using OAuth2 access token
          const sa = JSON.parse(GOOGLE_SERVICE_ACCOUNT_JSON);
          const tokenUri: string = sa.token_uri || "https://oauth2.googleapis.com/token";
          const accessToken = await getAccessToken(sa.client_email, sa.private_key, tokenUri);
          for (const t of tokenList) {
            const res = await fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({
                message: {
                  token: t,
                  notification: { title: `Round ${round} started`, body: "Open Asteria to see your table" },
                  data: { round: String(round) },
                },
              }),
            });
            if (res.ok) success += 1; else failure += 1;
          }
        }
        pushSummary = { success, failure };
      }
    } catch (e) {
      console.warn("Push send failed:", e);
    }

    return json({ ok: true, round, updated_at: new Date().toISOString(), push: pushSummary ?? null });
  } catch (e) {
    return json({ error: e?.message ?? String(e) }, 500);
  }
});

// Minimal JWT bearer token using service account for FCM HTTP v1
async function getAccessToken(clientEmail: string, privateKey: string, tokenUri: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64Url(JSON.stringify({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    exp: now + 3600,
    iat: now,
  }));
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${arrayBufferToBase64Url(signature)}`;

  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`token error: ${body?.error ?? res.status}`);
  return String(body.access_token);
}

function base64Url(input: string): string {
  return btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}
