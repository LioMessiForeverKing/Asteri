// Supabase Edge Function: get_matches
// - Authenticated user only (reads caller via anon token)
// - Uses service role to read minimal profile fields for others
// - Similarity: embeddings-first (cosine, clamped >=0), fallback to Jaccard on interests
// - Returns: top candidates with percent, star bucket, and up to 3 shared interests

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type CandidateRow = {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  star_color: string;
  interests: string[] | null;
};

type EmbedRow = { user_id: string; vector: any };

function dot(a: number[], b: number[]): number {
  let s = 0;
  for (let i = 0; i < a.length; i++) s += a[i] * b[i];
  return s;
}
function norm(a: number[]): number {
  return Math.sqrt(dot(a, a));
}
function cosineSimilarity(a: number[], b: number[]): number {
  const na = norm(a);
  const nb = norm(b);
  if (na === 0 || nb === 0) return 0;
  return dot(a, b) / (na * nb);
}

function parseVectorString(s: string): number[] {
  // Accept formats like "[0.1, -0.2, ...]" or "{0.1,-0.2,...}"
  const trimmed = s.trim().replace(/^[\[{]|[\]}]$/g, "");
  if (trimmed.length === 0) return [];
  return trimmed
    .split(",")
    .map((t) => Number(t))
    .filter((n) => Number.isFinite(n));
}
function toNumberArray(v: any): number[] {
  if (Array.isArray(v)) return v.map((x) => Number(x));
  if (typeof v === "string") return parseVectorString(v);
  return [];
}
function sanitizeVector(v: any, expectedDim: number): number[] | null {
  const arr = toNumberArray(v);
  if (!Array.isArray(arr) || arr.length === 0) return null;
  const out = new Array<number>(expectedDim).fill(0);
  const n = Math.min(expectedDim, arr.length);
  let hasFinite = false;
  for (let i = 0; i < n; i++) {
    const val = Number(arr[i]);
    if (Number.isFinite(val)) {
      out[i] = val;
      hasFinite = true;
    }
  }
  return hasFinite ? out : null;
}

function jaccard(a: string[] = [], b: string[] = []): number {
  const A = new Set(a.map((s) => s.toLowerCase()));
  const B = new Set(b.map((s) => s.toLowerCase()));
  const inter = [...A].filter((x) => B.has(x)).length;
  const union = new Set([...A, ...B]).size;
  return union === 0 ? 0 : inter / union;
}

function topSharedInterests(a: string[] = [], b: string[] = [], maxItems = 3): string[] {
  const A = new Set(a.map((s) => s.trim()).filter((s) => s.length > 0));
  const B = new Set(b.map((s) => s.trim()).filter((s) => s.length > 0));
  const inter = [...A].filter((x) => B.has(x));
  // Stable top: lowercase, then alphabetical
  inter.sort((x, y) => x.toLowerCase().localeCompare(y.toLowerCase()));
  return inter.slice(0, maxItems);
}

function percentAndStars(sim: number): { percent: number; stars: number } {
  const clamped = Math.max(0, Math.min(1, sim));
  const percent = Math.round(10 + 90 * clamped);
  const stars = percent >= 85 ? 5 : percent >= 70 ? 4 : percent >= 55 ? 3 : percent >= 40 ? 2 : 1;
  return { percent, stars };
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    const url = new URL(req.url);
    const limit = Math.max(1, Math.min(50, Number(url.searchParams.get("limit") ?? "20")));

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
    if (!SUPABASE_URL || !SERVICE_KEY || !ANON_KEY) {
      return new Response(JSON.stringify({ error: "Supabase env not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Use anon client to identify the caller from Authorization header
    const authed = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: userData, error: userError } = await authed.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const callerId = userData.user.id;

    // Service client bypasses RLS to read others' minimal fields
    const svc = createClient(SUPABASE_URL, SERVICE_KEY);

    // Load profiles and embeddings
    const [{ data: profiles, error: pErr }, { data: embeds, error: eErr }] = await Promise.all([
      svc.from("profiles").select("id, full_name, avatar_url, star_color, interests"),
      svc.from("user_embeddings").select("user_id, vector"),
    ]);
    if (pErr) throw pErr;
    if (eErr) throw eErr;

    const EXPECTED_DIM = Number(Deno.env.get("EMBED_DIM") ?? "3072");

    const embedByUser = new Map<string, number[]>();
    (embeds as EmbedRow[] | null)?.forEach((row) => {
      const v = sanitizeVector(row.vector, EXPECTED_DIM);
      if (v) embedByUser.set(row.user_id, v);
    });

    const callerProfile = (profiles as CandidateRow[]).find((p) => p.id === callerId);
    const callerVec = embedByUser.get(callerId) ?? null;
    const callerInterests = callerProfile?.interests ?? [];

    const candidates: any[] = [];
    for (const p of (profiles as CandidateRow[])) {
      if (p.id === callerId) continue;
      const vec = embedByUser.get(p.id) ?? null;
      let sim = 0;
      if (callerVec && vec) {
        sim = Math.max(0, cosineSimilarity(callerVec, vec));
      } else {
        sim = jaccard(callerInterests ?? [], p.interests ?? []);
      }
      const { percent, stars } = percentAndStars(sim);
      const shared = topSharedInterests(callerInterests ?? [], p.interests ?? [], 3);
      candidates.push({
        user_id: p.id,
        full_name: p.full_name ?? "",
        avatar_url: p.avatar_url ?? null,
        star_color: p.star_color,
        interests: p.interests ?? [],
        shared_interests: shared,
        scorePercent: percent,
        stars,
        similarity: sim,
      });
    }

    candidates.sort((a, b) => b.similarity - a.similarity || (a.user_id < b.user_id ? -1 : 1));
    const result = candidates.slice(0, limit).map(({ similarity, ...rest }) => rest);

    return new Response(JSON.stringify({ matches: result }), {
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


