// Assign users to clusters: computes or updates clustering and assigns the caller.
// Requires service role key (use with care). Reads all user_embeddings, runs k-means (k=10),
// upserts cluster centroids and assigns the authenticated user to the nearest centroid.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type KMeansOptions = { k: number; maxIters: number; seed?: number };

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

function kmeans(vectors: number[][], { k, maxIters, seed = 42 }: KMeansOptions) {
  // Clamp k to a safe value to avoid errors when there are few vectors
  const effectiveK = Math.max(1, Math.min(k, vectors.length));
  const rng = mulberry32(seed);
  // Initialize centroids by random selection
  const centroids: number[][] = [];
  const used = new Set<number>();
  while (centroids.length < effectiveK) {
    const idx = Math.floor(rng() * vectors.length);
    if (!used.has(idx)) {
      used.add(idx);
      centroids.push(vectors[idx].slice());
    }
  }

  const assignments = new Array<number>(vectors.length).fill(0);
  for (let iter = 0; iter < maxIters; iter++) {
    // Assign
    for (let i = 0; i < vectors.length; i++) {
      let best = 0;
      let bestScore = -Infinity;
      for (let c = 0; c < effectiveK; c++) {
        const score = cosineSimilarity(vectors[i], centroids[c]);
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
      assignments[i] = best;
    }
    // Recompute centroids
    const sums: number[][] = Array.from({ length: effectiveK }, () => new Array<number>(vectors[0].length).fill(0));
    const counts: number[] = new Array<number>(effectiveK).fill(0);
    for (let i = 0; i < vectors.length; i++) {
      const a = assignments[i];
      counts[a] += 1;
      const v = vectors[i];
      for (let j = 0; j < v.length; j++) sums[a][j] += v[j];
    }
    for (let c = 0; c < effectiveK; c++) {
      if (counts[c] === 0) continue;
      for (let j = 0; j < sums[c].length; j++) sums[c][j] /= counts[c];
      centroids[c] = sums[c];
    }
  }

  return { centroids, assignments };
}

function mulberry32(a: number) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

Deno.serve(async (req: Request): Promise<Response> => {
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return new Response(JSON.stringify({ error: "Supabase service env not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Identify caller via anon JWT (for assignment write to user_clusters)
    const authed = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY") || "", {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: userData, error: userError } = await authed.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const userId = userData.user.id;

    // Load all user embeddings
    const { data: embeds, error: embErr } = await supabase.from("user_embeddings").select("user_id, vector");
    if (embErr) throw embErr;
    if (!embeds || embeds.length === 0) {
      // Nothing to cluster yet; return a helpful 200 with message
      return new Response(JSON.stringify({ message: "no embeddings yet; run embed_youtube first" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    
    // Sanitize and normalize vectors to expected dimension, drop bad rows
    const EXPECTED_DIM = Number(Deno.env.get("EMBED_DIM") ?? "3072");
    function sanitize(v: any): number[] | null {
      if (!Array.isArray(v) || v.length === 0) return null;
      const out = new Array<number>(EXPECTED_DIM).fill(0);
      const n = Math.min(EXPECTED_DIM, v.length);
      let hasFinite = false;
      for (let i = 0; i < n; i++) {
        const val = Number(v[i]);
        if (Number.isFinite(val)) {
          out[i] = val;
          hasFinite = true;
        } else {
          out[i] = 0;
        }
      }
      return hasFinite ? out : null;
    }
    const cleaned = embeds
      .map((e: any) => ({ user_id: e.user_id, vector: sanitize(e.vector) }))
      .filter((e: any) => e.vector !== null);
    if (cleaned.length === 0) {
      return new Response(JSON.stringify({ message: "no valid embeddings yet; try re-embedding" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (embeds.length === 1) {
      // Single-user scenario: create cluster 0 as the user's vector and assign them
      const only = embeds[0];
      const centroid = only.vector as number[];
      await supabase.from("clusters").upsert([{ cluster_id: 0, centroid, created_at: new Date().toISOString() }], { onConflict: "cluster_id" });
      await supabase.from("user_clusters").upsert({ user_id: only.user_id, cluster_id: 0, similarity: 1.0, created_at: new Date().toISOString() });
      return new Response(JSON.stringify({ cluster_id: 0, similarity: 1.0 }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const vectors = cleaned.map((e: any) => (e.vector as number[]));
    // Choose a safe k based on available data
    const requestedK = Number(Deno.env.get("KMEANS_K") ?? "10");
    const k = Math.max(1, Math.min(requestedK, vectors.length));
    const { centroids, assignments } = kmeans(vectors, { k, maxIters: 15, seed: 42 });

    // Upsert clusters
    const clusterRows = centroids.map((c, idx) => ({ cluster_id: idx, centroid: c, created_at: new Date().toISOString() }));
    const { error: cluErr } = await supabase.from("clusters").upsert(clusterRows, { onConflict: "cluster_id" });
    if (cluErr) throw cluErr;

    // Find caller vector and its nearest centroid
    const indexOfCaller = cleaned.findIndex((e: any) => e.user_id === userId);
    if (indexOfCaller < 0) {
      return new Response(JSON.stringify({ error: "caller has no embedding yet" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    const callerVec = vectors[indexOfCaller];
    let best = 0;
    let bestScore = -Infinity;
    for (let c = 0; c < centroids.length; c++) {
      const score = cosineSimilarity(callerVec, centroids[c]);
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    const { error: assignErr } = await supabase
      .from("user_clusters")
      .upsert({ user_id: userId, cluster_id: best, similarity: bestScore, created_at: new Date().toISOString() });
    if (assignErr) throw assignErr;

    return new Response(JSON.stringify({ cluster_id: best, similarity: bestScore }), {
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


