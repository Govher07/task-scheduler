import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.27.0";

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Tool definitions ────────────────────────────────────────────────────────

const tools: Anthropic.Tool[] = [
  // Events
  {
    name: "get_events",
    description:
      "Retrieve calendar events. Optionally filter by date range or linked task.",
    input_schema: {
      type: "object",
      properties: {
        start_date: {
          type: "string",
          description: "Filter from this date, inclusive. Format: YYYY-MM-DD",
        },
        end_date: {
          type: "string",
          description: "Filter up to this date, inclusive. Format: YYYY-MM-DD",
        },
        task_id: {
          type: "string",
          description: "Only return events linked to this task ID",
        },
      },
    },
  },
  {
    name: "create_event",
    description: "Create a new calendar event.",
    input_schema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Event title. Extract a concise and descriptive title from the user's message (e.g., 'Meeting with ABC', '1:1 with XYZ'). If no specific details can be gleaned, use 'Meeting' as the fallback.",
        },
        start_time: {
          type: "string",
          description: "Start datetime in ISO 8601 format",
        },
        end_time: {
          type: "string",
          description: "End datetime in ISO 8601 format",
        },
        task_id: {
          type: "string",
          description: "Optional task ID to link this event to",
        },
        is_repeating: { type: "boolean" },
        recurrence_rule: {
          type: "string",
          description: "RRule string for recurring events",
        },
      },
      required: ["name", "start_time", "end_time"],
    },
  },
  {
    name: "update_event",
    description: "Update fields of an existing calendar event by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string", description: "Event ID to update" },
        name: { type: "string" },
        start_time: { type: "string" },
        end_time: { type: "string" },
        task_id: { type: "string" },
        is_repeating: { type: "boolean" },
        recurrence_rule: { type: "string" },
      },
      required: ["id"],
    },
  },
  {
    name: "delete_event",
    description: "Delete a calendar event by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string", description: "Event ID to delete" },
      },
      required: ["id"],
    },
  },

  // Goals
  {
    name: "get_goals",
    description: "Retrieve all goals. Optionally filter by type.",
    input_schema: {
      type: "object",
      properties: {
        type: {
          type: "string",
          enum: ["completable", "ongoing"],
          description: "Filter by goal type",
        },
      },
    },
  },
  {
    name: "create_goal",
    description: "Create a new goal.",
    input_schema: {
      type: "object",
      properties: {
        name: { type: "string" },
        type: { type: "string", enum: ["completable", "ongoing"] },
        description: { type: "string" },
        start_time: {
          type: "string",
          description: "Goal start date in ISO 8601 format",
        },
        deadline: {
          type: "string",
          description: "Goal deadline in ISO 8601 format",
        },
      },
      required: ["name", "type"],
    },
  },
  {
    name: "update_goal",
    description: "Update an existing goal by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string" },
        name: { type: "string" },
        type: { type: "string", enum: ["completable", "ongoing"] },
        description: { type: "string" },
        start_time: { type: "string" },
        deadline: { type: "string" },
      },
      required: ["id"],
    },
  },
  {
    name: "delete_goal",
    description: "Delete a goal by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string" },
      },
      required: ["id"],
    },
  },

  // Tasks
  {
    name: "get_tasks",
    description:
      "Retrieve tasks. Optionally filter by goal, status, or ungrouped.",
    input_schema: {
      type: "object",
      properties: {
        goal_id: {
          type: "string",
          description: "Only tasks belonging to this goal",
        },
        status: {
          type: "string",
          enum: ["todo", "inProgress", "done"],
        },
        ungrouped: {
          type: "boolean",
          description: "If true, return only tasks not linked to any goal",
        },
      },
    },
  },
  {
    name: "create_task",
    description: "Create a new task.",
    input_schema: {
      type: "object",
      properties: {
        name: { type: "string" },
        goal_id: { type: "string" },
        priority: { type: "string", enum: ["low", "medium", "high"] },
        start_time: { type: "string" },
        deadline: { type: "string" },
        estimated_duration_minutes: { type: "integer" },
        effort_level: { type: "string", enum: ["low", "medium", "high"] },
        status: { type: "string", enum: ["todo", "inProgress", "done"] },
      },
      required: ["name"],
    },
  },
  {
    name: "update_task",
    description: "Update an existing task by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string" },
        name: { type: "string" },
        goal_id: { type: "string" },
        priority: { type: "string", enum: ["low", "medium", "high"] },
        start_time: { type: "string" },
        deadline: { type: "string" },
        estimated_duration_minutes: { type: "integer" },
        effort_level: { type: "string", enum: ["low", "medium", "high"] },
        status: { type: "string", enum: ["todo", "inProgress", "done"] },
      },
      required: ["id"],
    },
  },
  {
    name: "delete_task",
    description: "Delete a task by ID.",
    input_schema: {
      type: "object",
      properties: {
        id: { type: "string" },
      },
      required: ["id"],
    },
  },

  // Recommendation
  {
    name: "recommend_task",
    description:
      "Recommend the single best task for the user to work on right now, based on the time they have available and (optionally) their current energy level. Ranks unfinished tasks by priority and deadline, filtering by how long they take and how much effort they require. Use this when the user asks what they should work on or do next.",
    input_schema: {
      type: "object",
      properties: {
        available_minutes: {
          type: "integer",
          description: "How many minutes the user has available right now.",
        },
        max_effort_level: {
          type: "string",
          enum: ["low", "medium", "high"],
          description:
            "Optional. The user's current energy ceiling — only tasks at or below this effort level are considered.",
        },
      },
      required: ["available_minutes"],
    },
  },
];

// ─── Tool executor ───────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
async function executeTool(supabase: any, userId: string, name: string, input: any) {
  const now = new Date().toISOString();

  switch (name) {
    // ── Events ──────────────────────────────────────────────────────────────
    case "get_events": {
      let q = supabase.from("events").select("*").eq("user_id", userId);
      if (input.start_date) q = q.gte("start_time", input.start_date);
      if (input.end_date) q = q.lte("start_time", `${input.end_date}T23:59:59`);
      if (input.task_id) q = q.eq("task_id", input.task_id);
      const { data, error } = await q.order("start_time");
      if (error) throw new Error(error.message);
      return data;
    }

    case "create_event": {
      const { data, error } = await supabase
        .from("events")
        .insert({
          id: crypto.randomUUID(),
          user_id: userId,
          name: input.name,
          start_time: input.start_time,
          end_time: input.end_time,
          task_id: input.task_id ?? null,
          is_repeating: input.is_repeating ?? false,
          recurrence_rule: input.recurrence_rule ?? null,
          created_at: now,
          updated_at: now,
        })
        .select()
        .single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "update_event": {
      const { id, ...rest } = input;
      // deno-lint-ignore no-explicit-any
      const patch: any = { updated_at: now };
      if (rest.name !== undefined) patch.name = rest.name;
      if (rest.start_time !== undefined) patch.start_time = rest.start_time;
      if (rest.end_time !== undefined) patch.end_time = rest.end_time;
      if (rest.task_id !== undefined) patch.task_id = rest.task_id;
      if (rest.is_repeating !== undefined) patch.is_repeating = rest.is_repeating;
      if (rest.recurrence_rule !== undefined) patch.recurrence_rule = rest.recurrence_rule;
      const { data, error } = await supabase
        .from("events").update(patch).eq("id", id).eq("user_id", userId).select().single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "delete_event": {
      const { error } = await supabase.from("events").delete().eq("id", input.id).eq("user_id", userId);
      if (error) throw new Error(error.message);
      return { deleted: true, id: input.id };
    }

    // ── Goals ───────────────────────────────────────────────────────────────
    case "get_goals": {
      let q = supabase.from("goals").select("*").eq("user_id", userId);
      if (input.type) q = q.eq("type", input.type);
      const { data, error } = await q.order("created_at");
      if (error) throw new Error(error.message);
      return data;
    }

    case "create_goal": {
      const { data, error } = await supabase
        .from("goals")
        .insert({
          id: crypto.randomUUID(),
          user_id: userId,
          name: input.name,
          type: input.type,
          description: input.description ?? null,
          starttime: input.start_time ?? null,
          deadline: input.deadline ?? null,
          created_at: now,
          updated_at: now,
        })
        .select()
        .single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "update_goal": {
      const { id, ...rest } = input;
      // deno-lint-ignore no-explicit-any
      const patch: any = { updated_at: now };
      if (rest.name !== undefined) patch.name = rest.name;
      if (rest.type !== undefined) patch.type = rest.type;
      if (rest.description !== undefined) patch.description = rest.description;
      if (rest.start_time !== undefined) patch.starttime = rest.start_time;
      if (rest.deadline !== undefined) patch.deadline = rest.deadline;
      const { data, error } = await supabase
        .from("goals").update(patch).eq("id", id).eq("user_id", userId).select().single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "delete_goal": {
      const { error } = await supabase.from("goals").delete().eq("id", input.id).eq("user_id", userId);
      if (error) throw new Error(error.message);
      return { deleted: true, id: input.id };
    }

    // ── Tasks ───────────────────────────────────────────────────────────────
    case "get_tasks": {
      let q = supabase.from("tasks").select("*").eq("user_id", userId);
      if (input.goal_id) q = q.eq("goal_id", input.goal_id);
      if (input.status) q = q.eq("status", input.status);
      if (input.ungrouped) q = q.is("goal_id", null);
      const { data, error } = await q.order("created_at");
      if (error) throw new Error(error.message);
      return data;
    }

    case "create_task": {
      const { data, error } = await supabase
        .from("tasks")
        .insert({
          id: crypto.randomUUID(),
          user_id: userId,
          name: input.name,
          goal_id: input.goal_id ?? null,
          priority: input.priority ?? "medium",
          starttime: input.start_time ?? null,
          deadline: input.deadline ?? null,
          estimated_duration_minutes: input.estimated_duration_minutes ?? null,
          effort_level: input.effort_level ?? "medium",
          status: input.status ?? "todo",
          created_at: now,
          updated_at: now,
        })
        .select()
        .single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "update_task": {
      const { id, ...rest } = input;
      // deno-lint-ignore no-explicit-any
      const patch: any = { updated_at: now };
      if (rest.name !== undefined) patch.name = rest.name;
      if (rest.goal_id !== undefined) patch.goal_id = rest.goal_id;
      if (rest.priority !== undefined) patch.priority = rest.priority;
      if (rest.start_time !== undefined) patch.starttime = rest.start_time;
      if (rest.deadline !== undefined) patch.deadline = rest.deadline;
      if (rest.estimated_duration_minutes !== undefined) {
        patch.estimated_duration_minutes = rest.estimated_duration_minutes;
      }
      if (rest.effort_level !== undefined) patch.effort_level = rest.effort_level;
      if (rest.status !== undefined) patch.status = rest.status;
      const { data, error } = await supabase
        .from("tasks").update(patch).eq("id", id).eq("user_id", userId).select().single();
      if (error) throw new Error(error.message);
      return data;
    }

    case "delete_task": {
      const { error } = await supabase.from("tasks").delete().eq("id", input.id).eq("user_id", userId);
      if (error) throw new Error(error.message);
      return { deleted: true, id: input.id };
    }

    // ── Recommendation ───────────────────────────────────────────────────────
    // Ranking mirrors lib/features/recommender/scoring.dart — keep the two in
    // sync: priority descending, then soonest deadline (nulls last). Here we
    // additionally filter/rank by time available and effort level.
    case "recommend_task": {
      const priorityRank: Record<string, number> = { low: 1, medium: 2, high: 3 };
      const effortRank: Record<string, number> = { low: 1, medium: 2, high: 3 };

      const availableMinutes: number | null =
        typeof input.available_minutes === "number"
          ? input.available_minutes
          : null;
      const maxEffort: number | null = input.max_effort_level
        ? effortRank[input.max_effort_level] ?? null
        : null;

      const { data: tasks, error } = await supabase
        .from("tasks")
        .select("*")
        .eq("user_id", userId)
        .neq("status", "done");
      if (error) throw new Error(error.message);

      // deno-lint-ignore no-explicit-any
      const fitsTime = (t: any): boolean => {
        if (availableMinutes === null) return true;
        if (t.estimated_duration_minutes == null) return false;
        return t.estimated_duration_minutes <= availableMinutes;
      };

      const candidates = (tasks ?? []).filter((t: any) => {
        // Effort filter: skip tasks above the user's current energy ceiling.
        if (maxEffort !== null) {
          const e = effortRank[t.effort_level] ?? 2;
          if (e > maxEffort) return false;
        }
        return true;
      });

      // Time-fitting tasks rank ahead of non-fitting / no-estimate fallbacks,
      // then priority desc, then soonest deadline (nulls last).
      candidates.sort((a: any, b: any) => {
        const aFits = fitsTime(a) ? 0 : 1;
        const bFits = fitsTime(b) ? 0 : 1;
        if (aFits !== bFits) return aFits - bFits;

        const ap = priorityRank[a.priority] ?? 2;
        const bp = priorityRank[b.priority] ?? 2;
        if (ap !== bp) return bp - ap;

        const ad = a.deadline ? Date.parse(a.deadline) : Infinity;
        const bd = b.deadline ? Date.parse(b.deadline) : Infinity;
        return ad - bd;
      });

      const best = candidates[0];
      if (!best) {
        return {
          recommendation: null,
          reason:
            "No unfinished tasks match the given time and energy. Suggest the user widen the available time or raise the energy level.",
        };
      }

      const reasonParts: string[] = [`${best.priority ?? "medium"} priority`];
      if (best.deadline) {
        const days = Math.ceil((Date.parse(best.deadline) - Date.now()) / 86400000);
        reasonParts.push(
          days <= 0 ? "due now" : days === 1 ? "due tomorrow" : `due in ${days} days`,
        );
      }
      if (best.estimated_duration_minutes != null) {
        reasonParts.push(`~${best.estimated_duration_minutes} min`);
      }
      if (best.effort_level) reasonParts.push(`${best.effort_level} effort`);
      if (availableMinutes !== null && !fitsTime(best)) {
        reasonParts.push(
          "(best available task, but may not fit the given time window)",
        );
      }

      return {
        recommendation: best,
        reason: reasonParts.join(", "),
        fits_time_window: fitsTime(best),
      };
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { messages } = await req.json() as {
      messages: Anthropic.MessageParam[];
    };

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // verify_jwt is off, so authenticate the caller here: read the access token
    // the app sends in the Authorization header and resolve it to a user. Every
    // tool is then scoped to this user's own rows so the AI can never see or
    // touch another user's data.
    const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
    let userId: string | null = null;
    if (token) {
      const { data } = await supabase.auth.getUser(token);
      userId = data.user?.id ?? null;
    }
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: a valid user session is required." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const system = `You are an AI assistant embedded in a personal task-scheduler app.
You help users manage their calendar events, goals, and tasks through conversation.
Today's date is ${new Date().toISOString().split("T")[0]}.

Guidelines:
- Use tools to read data before making changes so you can reference real names and IDs.
- For destructive operations (delete), confirm with the user first unless they've already confirmed.
- Be concise and friendly.
- Always respond in the same language the user writes in.
- When creating events, intelligently parse the title. Do not include time/date words in the title (e.g., use "Meeting" instead of "A meeting tomorrow at 3pm"). Fallback to "Meeting" if no specific details can be gleaned from the message.
- When the user asks what to work on or for a recommendation, use the recommend_task tool. If you don't yet know how much time they have, ask for their available minutes first (and optionally their current energy level: low, medium, or high). After recommending, briefly explain why that task — referencing its priority, deadline, effort, and how it fits their time — then offer to schedule it.
- When the user agrees to schedule a recommended task, use create_event: set the event name to the task name, link it with the recommended task's id via task_id, start at the current time (or a time the user specifies), and end after the task's estimated duration (fall back to the time the user has available if there is no estimate).`;

    // Agentic loop — keep going until Claude stops calling tools
    let currentMessages: Anthropic.MessageParam[] = [...messages];

    while (true) {
      const response = await anthropic.messages.create({
        model: "claude-sonnet-4-6",
        max_tokens: 1024,
        system,
        messages: currentMessages,
        tools,
      });

      if (response.stop_reason === "end_turn") {
        const text = response.content.find((b) => b.type === "text");
        return new Response(
          JSON.stringify({ reply: text?.text ?? "" }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      if (response.stop_reason === "tool_use") {
        // Append Claude's turn (which includes tool_use blocks)
        currentMessages.push({ role: "assistant", content: response.content });

        // Execute every tool call in parallel
        const toolResults = await Promise.all(
          response.content
            .filter((b): b is Anthropic.ToolUseBlock => b.type === "tool_use")
            .map(async (block) => {
              let result: unknown;
              try {
                result = await executeTool(supabase, userId, block.name, block.input);
              } catch (err: unknown) {
                result = { error: err instanceof Error ? err.message : String(err) };
              }
              return {
                type: "tool_result" as const,
                tool_use_id: block.id,
                content: JSON.stringify(result),
              };
            }),
        );

        currentMessages.push({ role: "user", content: toolResults });
        continue;
      }

      // Unexpected stop reason
      break;
    }

    return new Response(
      JSON.stringify({ reply: "Sorry, something went wrong." }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err: unknown) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
