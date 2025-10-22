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

    return json({ ok: true, round, updated_at: new Date().toISOString() });
  } catch (e) {
    return json({ error: e?.message ?? String(e) }, 500);
  }
});


