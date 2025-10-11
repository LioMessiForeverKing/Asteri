// Supabase Edge Function: embed_youtube
// - Authenticated user only
// - Body: { texts: string[], model?: string, source?: string }
// - Calls OpenAI embeddings API, mean-pools vectors, upserts into public.user_embeddings

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type EmbedRequest = {
  texts?: string[];
  model?: string;
  source?: string;
};

function isNonEmptyString(s: unknown): s is string {
  return typeof s === "string" && s.trim().length > 0;
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    const { texts, model = "text-embedding-3-large", source = "youtube" } = (await req.json().catch(() => ({}))) as EmbedRequest;

    if (!Array.isArray(texts) || texts.length === 0) {
      return new Response(JSON.stringify({ error: "texts (string[]) required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const filtered = texts.filter(isNonEmptyString).map((t) => t.trim());
    if (filtered.length === 0) {
      return new Response(JSON.stringify({ error: "no non-empty texts provided" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      return new Response(JSON.stringify({ error: "OPENAI_API_KEY not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      return new Response(JSON.stringify({ error: "Supabase env not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const userId = userData.user.id;

    // Call OpenAI embeddings
    const openaiRes = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        input: filtered,
      }),
    });

    if (!openaiRes.ok) {
      const bodyText = await openaiRes.text();
      return new Response(
        JSON.stringify({ error: "openai_error", status: openaiRes.status, body: bodyText }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const openaiJson = await openaiRes.json();
    const rawVectors: unknown[] = openaiJson?.data ?? [];
    const vectors: number[][] = rawVectors
      .map((d: any) => (Array.isArray(d?.embedding) ? d.embedding as number[] : []))
      .filter((arr: number[]) => Array.isArray(arr) && arr.length > 0);
    if (!Array.isArray(vectors) || vectors.length === 0) {
      return new Response(JSON.stringify({ error: "no embeddings returned" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Enforce expected dimension and sanitize values
    const EXPECTED_DIM = Number(Deno.env.get("EMBED_DIM") ?? "3072");
    const dim = Math.min(EXPECTED_DIM, vectors[0].length);
    const mean = new Array<number>(EXPECTED_DIM).fill(0);
    for (const v of vectors) {
      // Normalize each vector to the expected length via slice/pad
      const safeV: number[] = new Array<number>(EXPECTED_DIM).fill(0);
      for (let i = 0; i < Math.min(v.length, EXPECTED_DIM); i++) {
        const val = v[i];
        safeV[i] = Number.isFinite(val) ? val : 0;
      }
      for (let i = 0; i < EXPECTED_DIM; i++) mean[i] += safeV[i];
    }
    for (let i = 0; i < EXPECTED_DIM; i++) {
      const avg = mean[i] / vectors.length;
      mean[i] = Number.isFinite(avg) ? avg : 0;
    }

    const { error: upsertError } = await supabase
      .from("user_embeddings")
      .upsert({ user_id: userId, source, vector: mean, updated_at: new Date().toISOString() });

    if (upsertError) {
      return new Response(JSON.stringify({ error: upsertError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ embedded_count: filtered.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e?.message ?? String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});


