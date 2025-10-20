// Supabase Edge Function (TypeScript) – proxies OpenAI and returns graph JSON
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

type Sub = { snippet?: { title?: string } };
type Like = { snippet?: { title?: string; description?: string; channelTitle?: string } };

serve(async (req: Request) => {
  try {
    const { subscriptions = [], likedVideos = [], model = 'gpt-4.1-nano' } = await req.json();
    const openaiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openaiKey) throw new Error('Missing OPENAI_API_KEY');

    const payload = {
      subs: (subscriptions as Sub[]).map((s) => s?.snippet?.title).filter(Boolean).slice(0, 150),
      likes: (likedVideos as Like[]).map((l) => ({
        t: l?.snippet?.title, d: l?.snippet?.description, c: l?.snippet?.channelTitle,
      })).slice(0, 200),
    };

    const system = `You will generate a concise JSON graph with exactly 15 nodes labelled by passions and weighted 0..1, and edges with similarity 0..1. Respond ONLY with JSON of shape {nodes:[{id,label,weight,clusterTag?,colorSeed?}], edges:[{sourceId,targetId,weight}]}. Ensure sparse edges (avg degree ~3).`;
    const user = JSON.stringify(payload).slice(0, 12000);

    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
        temperature: 0.4,
        response_format: { type: 'json_object' },
      }),
    });

    if (!resp.ok) {
      const text = await resp.text();
      return new Response(JSON.stringify({ error: 'openai_error', detail: text }), { status: 500 });
    }
    const data = await resp.json();
    const content = data?.choices?.[0]?.message?.content;
    return new Response(JSON.stringify({ graph: content }), { headers: { 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'server_error', detail: String(e) }), { status: 500 });
  }
});


