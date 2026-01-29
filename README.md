# coffee_arq_app

A new Flutter project.

## Structure

- `lib/main.dart`: App shell + theme
- `lib/screens/`: Screen files (home, menu, orders, account)
- `lib/theme/`: Color palette
- `lib/data/`: Supabase client

## Getting Started

## Stripe (Supabase Edge Function)

1) Install Supabase CLI and login.
2) Create and deploy the function:

```
supabase functions new create-payment-intent
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase functions deploy create-payment-intent
```

3) Add the function code (see below) to `supabase/functions/create-payment-intent/index.ts`

```ts
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
});

Deno.serve(async (req) => {
  const { amount, currency = "usd" } = await req.json();
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
  });
  return new Response(
    JSON.stringify({ client_secret: paymentIntent.client_secret }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
