// edge-function-share.ts — Supabase Edge Function handler sketch (Deno).
// UNVERIFIED-SNIPPET: composed from documented patterns; NOT executed live.
// Pattern: service-role client ONLY inside the function, never in the app;
// never trust an id/role sent in the request body as identity.
// The shareId is a capability looked up server-side; a wrong/unknown id
// returns the same 404 as a missing one (no existence oracle).
// verify_jwt = false in supabase/config.toml for this ONE function is
// DELIBERATE (no-accounts demo, no user JWT exists) — the in-handler
// shareId check below replaces the gateway check. Never set verify_jwt
// = false on a function that calls a paid external API without an
// in-handler credential check. (verify_jwt behaviour sourced from the
// official docs mirror at
// https://github.com/itsjamiedev/supabase/blob/HEAD/apps/docs/content/guides/functions/auth.mdx
// — the official supabase.com Edge Functions docs page is CHƯA ĐỌC.)

import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // server-side ONLY; bypasses RLS by design
);

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });
  const body = await req.json().catch(() => null);
  const shareId = body?.shareId;
  // 1. Format-check the credential; reject anything else before touching the DB.
  if (typeof shareId !== "string" || !UUID_RE.test(shareId)) {
    return new Response(JSON.stringify({ error: "not_found" }), { status: 404 });
  }
  // 2. Server-side lookup by that id ONLY. No client-sent userId is read, ever.
  const { data, error } = await supabaseAdmin
    .from("shares")
    .select("id, title, payload, updated_at")
    .eq("id", shareId)
    .maybeSingle();
  if (error || !data) {
    return new Response(JSON.stringify({ error: "not_found" }), { status: 404 });
  }
  return Response.json(data);
});
