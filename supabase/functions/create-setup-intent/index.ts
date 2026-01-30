import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
});

Deno.serve(async () => {
  const setupIntent = await stripe.setupIntents.create({
    usage: "off_session",
  });
  return new Response(
    JSON.stringify({ client_secret: setupIntent.client_secret }),
    { headers: { "Content-Type": "application/json" } },
  );
});
