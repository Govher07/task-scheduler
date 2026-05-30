/**
 * create-event — Supabase Edge Function
 *
 * POST /functions/v1/create-event
 *
 * Creates a new calendar event in the `events` table.
 * Designed to be called by bots, the support-chat AI, or any external
 * integration WITHOUT needing to go through the AI assistant conversation loop.
 *
 * Request body (JSON):
 * {
 *   "name":             string  — required  — event title
 *   "start_time":       string  — required  — ISO 8601, e.g. "2026-06-01T10:00:00"
 *   "end_time":         string  — required  — ISO 8601, e.g. "2026-06-01T11:00:00"
 *   "task_id":          string? — optional  — link to an existing task
 *   "is_repeating":     boolean?— optional  — default false
 *   "recurrence_rule":  string? — optional  — RRULE string, e.g. "RRULE:FREQ=WEEKLY;BYDAY=FR"
 * }
 *
 * Success response (201):
 * {
 *   "event": { ...created event row }
 * }
 *
 * Error response (400 / 500):
 * {
 *   "error": "human-readable message"
 * }
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    const body = await req.json();

    // ── Validate required fields ──────────────────────────────────────────────
    const { name, start_time, end_time, task_id, is_repeating, recurrence_rule } = body;

    if (!name || typeof name !== "string" || name.trim() === "") {
      return new Response(
        JSON.stringify({ error: "'name' is required and must be a non-empty string." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!start_time || isNaN(Date.parse(start_time))) {
      return new Response(
        JSON.stringify({ error: "'start_time' is required and must be a valid ISO 8601 datetime." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!end_time || isNaN(Date.parse(end_time))) {
      return new Response(
        JSON.stringify({ error: "'end_time' is required and must be a valid ISO 8601 datetime." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (new Date(end_time) <= new Date(start_time)) {
      return new Response(
        JSON.stringify({ error: "'end_time' must be after 'start_time'." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Insert into Supabase ──────────────────────────────────────────────────
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const now = new Date().toISOString();

    const { data, error } = await supabase
      .from("events")
      .insert({
        id: crypto.randomUUID(),
        name: name.trim(),
        start_time,
        end_time,
        task_id: task_id ?? null,
        is_repeating: is_repeating ?? false,
        recurrence_rule: recurrence_rule ?? null,
        created_at: now,
        updated_at: now,
      })
      .select()
      .single();

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ event: data }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err: unknown) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
