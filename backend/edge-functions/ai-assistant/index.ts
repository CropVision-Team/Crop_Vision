// Supabase Edge Function - AI Assistant
// -----------------------------------------
// Runs server-side (Deno), so it works identically from Chrome web AND
// the native Android app - the actual call to Anthropic's API happens
// here, not in the browser/app, which avoids CORS entirely (Anthropic's
// API blocks direct browser requests; this function is the "backend"
// standing in between).
//
// Deploy this with the Supabase CLI (see README section below for
// exact commands). Requires an Anthropic API key set as a secret.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Browsers send a CORS preflight OPTIONS request before the real one -
  // must answer that or the actual POST never happens.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { message, diagnosisContext } = await req.json();

    if (!message || typeof message !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing 'message' in request body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY secret not set on this function" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const systemPrompt =
      "You are a helpful assistant for a crop disease detection app used by " +
      "farmers. Answer questions about crop diseases, treatment, prevention, " +
      "and general farming practices. Keep answers concise and practical - " +
      "farmers may be reading this on a phone in the field. " +
      (diagnosisContext
        ? `\n\nThe farmer's most recent diagnosis: ${diagnosisContext}`
        : "");

    const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 500,
        system: systemPrompt,
        messages: [{ role: "user", content: message }],
      }),
    });

    if (!anthropicResponse.ok) {
      const errText = await anthropicResponse.text();
      return new Response(
        JSON.stringify({ error: `Anthropic API error: ${errText}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const data = await anthropicResponse.json();
    const reply = data.content?.[0]?.text ?? "No response generated.";

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Function error: ${e}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
