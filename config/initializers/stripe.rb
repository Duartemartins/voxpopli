# Stripe configuration
stripe_creds = Rails.application.credentials.dig(Rails.env.to_sym, :stripe) || Rails.application.credentials.dig(:stripe)

Stripe.api_key = stripe_creds&.dig(:secret_key) || ENV["STRIPE_SECRET_KEY"]

# Stripe API version
Stripe.api_version = "2024-12-18.acacia"

# For webhook signature verification
Rails.application.config.stripe_webhook_secret = stripe_creds&.dig(:webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"]
Rails.application.config.stripe_publishable_key = stripe_creds&.dig(:publishable_key) || ENV["STRIPE_PUBLISHABLE_KEY"]
