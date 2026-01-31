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

## Staff Dashboard (Supabase tables)

Add/verify these tables/columns for the staff dashboard:

```sql
-- Stores
create table if not exists stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_open boolean not null default true
);

-- Store-specific drink availability
create table if not exists store_drink_availability (
  store_id uuid references stores(id) on delete cascade,
  drink_id uuid references drinks(id) on delete cascade,
  is_available boolean not null default true,
  primary key (store_id, drink_id)
);

-- Orders (ensure these columns exist)
alter table orders
  add column if not exists store_name text,
  add column if not exists store_id uuid;

-- Users (role for staff/admin)
alter table users
  add column if not exists role text default 'customer';

-- Drinks (ensure availability flag exists)
alter table drinks
  add column if not exists is_available boolean not null default true;
```

Status values used in the app:
- `received` → `preparing` → `ready` → `completed`

Roles used in the app:
- `customer` (default)
- `staff` (store workers)
- `admin` (brand/platform admins)

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
