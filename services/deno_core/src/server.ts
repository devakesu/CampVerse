import { type Context, Hono } from 'hono';
import { cors } from 'hono/cors';
import { authRouter } from './routes/auth.ts';
import { institutesRouter } from './routes/institutes.ts';

const app = new Hono();

// Global CORS Middleware
app.use(
  '*',
  cors({
    origin: (origin: string): string => origin || '*',
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Authorization', 'Content-Type', 'Accept', 'Origin', 'X-Requested-With'],
    exposeHeaders: ['Content-Length', 'X-Kuma-Revision'],
    maxAge: 86400,
    credentials: true,
  }),
);

// Health Check
app.get('/health', (c: Context): Response => {
  return c.json({ status: 'online', service: 'campverse-deno-api' });
});

// Mount Auth routes (accessible via direct proxy or /api gateway)
app.route('/auth', authRouter);
app.route('/api/auth', authRouter);

// Mount Institutes routes (accessible via direct proxy or /api gateway)
app.route('/institutes', institutesRouter);
app.route('/api/institutes', institutesRouter);

// Razorpay webhooks
app.post('/webhooks/razorpay', (c: Context): Response => {
  return c.json({ received: true });
});

Deno.serve({ port: 8000 }, app.fetch);


