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
