import { Hono } from "hono";

const app = new Hono();

app.get("/health", (c) => {
  return c.json({ status: "online", service: "campverse-deno-api" });
});

app.post("/webhooks/razorpay", async (c) => {
  return c.json({ received: true });
});

Deno.serve({ port: 8000 }, app.fetch);
