// Phase 3: reads current round and user schedule from DB
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY');
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      return json({ error: 'server not configured' }, 500);
    }

    const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });

    const { data: userData } = await client.auth.getUser();
    const userId = userData?.user?.id;
    if (!userId) return json({ error: 'unauthorized' }, 401);

    const { data: current, error: cErr } = await client
      .from('current_round')
      .select('round, updated_at')
      .eq('id', 1)
      .maybeSingle();
    if (cErr) return json({ error: cErr.message }, 500);
    const round = current?.round ?? 1;

    const { data: sched, error: sErr } = await client
      .from('user_rounds')
      .select('round, table_label')
      .eq('user_id', userId);
    if (sErr) return json({ error: sErr.message }, 500);

    const map = new Map<number, string>();
    (sched ?? []).forEach((r: any) => map.set(Number(r.round), String(r.table_label)));
    const table = map.get(Number(round)) ?? 'Unassigned';

    return json({ table_label: table, round, updated_at: current?.updated_at ?? null, scope: 'per-user' }, 200);
  } catch (e) {
    return json({ error: e?.message ?? String(e) }, 500);
  }
});


