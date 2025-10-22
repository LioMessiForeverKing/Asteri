// Phase 1 stub: admin-only switch with in-memory state and realtime broadcast.
// Security note: Real admin enforcement added in Phase 4. For now, accept any authed call.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

let currentTable: 'X' | 'Y' | 'Z' = 'X';

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function isValidTableLabel(x: unknown): x is 'X' | 'Y' | 'Z' {
  return x === 'X' || x === 'Y' || x === 'Z';
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return json({ error: 'method not allowed' }, 405);
  }

  try {
    const { table_label, audience, message } = await req.json().catch(() => ({}));
    if (!isValidTableLabel(table_label)) {
      return json({ error: 'invalid table_label (must be X|Y|Z)' }, 400);
    }

    // Update in-memory state
    currentTable = table_label;

    // Publish realtime broadcast on `assignment` channel
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY');
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      // For local dev, allow missing env and skip publish
      console.warn('Missing SUPABASE_URL or SUPABASE_ANON_KEY; skipping realtime publish');
    } else {
      const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
      });
      try {
        // Supabase Realtime broadcast via postgres is not directly exposed from edge; use Channels
        // Use the Broadcast API
        const channel = client.channel('assignment');
        await channel.subscribe(async (status) => {
          if (status === 'SUBSCRIBED') {
            await channel.send({ type: 'broadcast', event: 'assignment.changed', payload: { table_label, ts: new Date().toISOString() } });
            await channel.unsubscribe();
          }
        });
        // Give some small time window; not critical in Phase 1
        await new Promise((r) => setTimeout(r, 150));
      } catch (e) {
        console.warn('Realtime publish failed:', e);
      }
    }

    const publishedAt = new Date().toISOString();
    return json({ ok: true, broadcast_id: crypto.randomUUID(), table_label, audience: audience ?? 'all', published_at: publishedAt }, 200);
  } catch (e) {
    return json({ error: e?.message ?? String(e) }, 500);
  }
});


