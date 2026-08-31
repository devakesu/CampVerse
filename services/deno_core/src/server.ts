import { Hono } from 'hono';
import { authRouter } from './routes/auth.ts';

const app = new Hono();

// Health Check
app.get('/health', (c) => {
  return c.json({ status: 'online', service: 'campverse-deno-api' });
});

// Mount Auth routes (accessible via direct proxy or /api gateway)
app.route('/auth', authRouter);
app.route('/api/auth', authRouter);

// Razorpay webhooks
app.post('/webhooks/razorpay', (c) => {
  return c.json({ received: true });
});

Deno.serve({ port: 8000 }, app.fetch);
