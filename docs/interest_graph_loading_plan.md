## Asteria Loading Page – Passion Graph (Design Plan)

This document describes how the new loading experience will analyze a user’s YouTube activity using OpenAI gpt-4.1-nano and render a 15‑node animated “neural” knowledge graph on a white background, optimized for mobile.

### Goals
- **Personalized graph**: Derive ~15 passions from ~100 liked videos and subscribed channels, plus their relationships.
- **Smooth loading**: Progressive, calm animation while data streams and processing completes.
- **Delightful visual**: Futuristic force‑directed graph with subtle motion and organic edge growth.
- **Mobile-first**: 60fps target, readable labels, accessible contrast.
- **Simple flow**: On completion, show “Screenshot this and click Continue”; reveal Continue after 2s; navigate to Community page.

### Data and Intelligence
- **Input sources**
  - Liked videos (first ~100) and subscribed channels (cap or batch streamed).
  - Minimal payload: channel names, categories (if available), video titles, descriptions, tags.
- **Model**: OpenAI `gpt-4.1-nano` summarization over a compacted JSON.
- **Model output (strict JSON)**
  - `nodes` (15): `{ id, label, weight[0-1], clusterTag?, colorSeed? }`
  - `edges`: `{ sourceId, targetId, similarity[0-1] }`
  - Optional: `styleHints` per cluster (e.g., technical/artsy) for color mapping.
- **Validation & retries**
  - Enforce JSON schema; on invalid output retry with reduced payload and stricter instructions.
  - Redact any user identifiers; only content text is sent.
- **Caching**
  - Persist passions/edges in Supabase so returning users skip the heavy pass.

### Graph Data Model (App)
- **Node**: `id`, `label`, `weight`, `position(x,y)`, `velocity(x,y)`, `clusterTag`, `colorSeed`.
- **Edge**: `sourceId`, `targetId`, `weight` (from similarity).
- **Derived**
  - Node radius from `weight` (min/max clamp for legibility).
  - Edge thickness/opacity from similarity; color palette by `clusterTag`.
  - Top‑K edges per node (K≈3–4) to keep the graph readable (≈35–45 total edges).

### Rendering & Animation
- **Canvas approach**: `CustomPainter` with a lightweight force simulation.
  - Forces: node‑node repulsion, spring edges, gentle centering, minimal damping.
  - Continuous micro‑motion (low‑amplitude drift) to keep the scene alive.
  - Velocity clamping to prevent jitter; frame‑time adaptive step.
- **Aesthetic**
  - White background with a faint grid.
  - Nodes: soft glow/gradient, subtle shadow.
  - Edges: slightly curved; alpha‑blended; thicker for stronger relationships.
  - Labels: crisp, collision‑aware placement just outside nodes.

### Timeline (Phased Loading)
1) Background + grid fade in (200–300ms).
2) Nodes spawn in a ring, scale 0.7→1.0 with gentle overshoot (600–900ms; staggered).
3) Labels fade in per node (100–150ms delay each).
4) Edges “grow” along top‑K similarities (stroke length 0→1 over ~500ms; staggered, organic ordering).
5) Ambient micro‑motion continues; periodic synchronized pulse every ~4–6s.
6) When OpenAI + embeddings + persistence complete:
   - Show message: “Screenshot this and click Continue”.
   - Reveal Continue button after 2s; tap navigates to `CommunityPage`.

### Orchestration & State
- **Pipeline**
  1. Sync YouTube data (paged batches to keep UI responsive).
  2. Submit compacted JSON to `gpt-4.1-nano`; receive nodes/edges.
  3. Normalize, cap to 15 nodes with diversity filter; compute layout seeds.
  4. Persist nodes/edges in Supabase; cache snapshot.
  5. Drive phased render; progressively hydrate as data becomes available.
- **Progress UI**
  - Friendly messages: “Mapping your digital footprint…”, “Analyzing your social graph…”, “Discovering your connection patterns…”, “Finding your tribe…”, “Almost ready…”.
  - Maintain smooth animation even while awaiting network/model responses.

### Performance & UX Safeguards (Mobile)
- Cache text layouts for labels; reuse paints; minimize allocations per frame.
- Run heavy similarity normalization and layout prep on a background isolate.
- Strict node count (15) and edge cap (≈45) for readability and performance.
- Incremental hydration: show skeleton nodes first, fill labels/edges as data arrives.
- Network/model fallbacks:
  - If model is slow/unavailable: derive a basic graph from TF‑IDF/embedding similarity locally and continue flow.
  - On failure, keep ambient animation and present a discreet “Retry”.

### Privacy & Telemetry
- Redact user identifiers; store only derived graph data and aggregate signals.
- Telemetry (anonymized): phase durations, model latency, fallback usage, frame drops.

### Completion Behavior
- On pipeline completion, display the instruction text.
- After a 2‑second delay, animate in the Continue button.
- Continue navigates to the `CommunityPage` and stores a graph snapshot reference for quick rehydration on next launch.



### Step-by-Step Implementation Plan (with Tests)

1) OpenAI integration
   - Create `OpenAIService` to call `gpt-4.1-nano` with a compact JSON payload (liked videos + subs) and strict response schema.
   - Add request chunking (token guard) and retry with stricter prompt on invalid JSON.
   - Tests
     - Unit: schema validator passes for valid sample, rejects malformed; retry path trims payload.
     - Unit: redaction removes PII fields; payload size remains under threshold.

2) Data pipeline orchestrator
   - Implement a controller that sequences: YouTube sync → OpenAI summarize → normalize → persist to Supabase → notify UI phases.
   - Stream partial progress so UI can progressively reveal nodes/labels/edges.
   - Tests
     - Integration: mock YouTube + OpenAI + Supabase; verify ordered calls and state transitions.
     - Integration: failure cases (OpenAI timeout, network error) trigger fallback graph and still complete.

3) Graph domain model
   - Define `PassionNode`, `GraphEdge`, and `GraphSnapshot` with serialization.
   - Implement diversity filter and top‑K edge pruning.
   - Tests
     - Unit: radius/opacity mapping functions; diversity filter maintains label variety; top‑K capping yields ≤45 edges.
     - Unit: deterministic seeding for layout given same input.

4) Layout & force simulation
   - Build a lightweight force simulator (repulsion, spring, centering, damping) tuned for 15 nodes; add micro‑drift.
   - Provide hooks for phased animation (spawn ring → settle → continuous motion).
   - Tests
     - Unit: step function reduces total energy over time (stability); velocity clamp respected.
     - Performance: micro-benchmark steps/ms within mobile budget.

5) Rendering (Canvas)
   - Implement `CustomPainter` for nodes, labels, curved edges, glow/shadows; cache text layouts and paints.
   - Add label collision avoidance and pixel‑snap for crisp text.
   - Tests
     - Golden tests: small/medium scenes render as expected across devices DPRs.
     - Widget test: painter rebuilds are throttled; no exceptions when labels overlap.

6) Phased animation timeline
   - Orchestrate phases: background/grid fade → node spawn → label fade → edge grow → ambient pulse.
   - Keep animation running smoothly during async waits.
   - Tests
     - Widget test: timeline advances with fake clock; elements appear in order.
     - Integration: timeline remains responsive while mocked network delays occur.

7) Completion UX and navigation
   - Display message “Screenshot this and click Continue” when processing is done.
   - Delay 2s, then reveal Continue with slide/fade; on tap, navigate to `CommunityPage`.
   - Persist `GraphSnapshot` reference for rehydration.
   - Tests
     - Widget test: button becomes visible after 2s; tap triggers navigation intent.
     - Integration: snapshot saved; returning session bypasses heavy processing and draws from cache.

8) Fallback path (no OpenAI)
   - Compute local similarities using TF‑IDF or embeddings; generate a reduced graph.
   - Maintain same UI timeline; mark telemetry as fallback_used.
   - Tests
     - Integration: forced failure of OpenAI yields valid graph and successful completion.

9) Accessibility & polish
   - Ensure label contrast, dynamic type support, and haptic on node tap.
   - Provide reduced motion option to damp animations.
   - Tests
     - Accessibility checks: contrast ratios; semantics exist for message and button.

10) Telemetry & QA
   - Record phase timings, model latency, frame drops (anonymized).
   - Dogfood on target devices; fix any frame hitches >16ms spikes.
   - Tests
     - Unit: telemetry envelopes redact identifiers; sampling rate respected.

