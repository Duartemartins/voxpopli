# Stripe configuration
Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]

# Stripe API version
Stripe.api_version = "2024-12-18.acacia"

# For webhook signature verification
Rails.application.config.stripe_webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"]
Rails.application.config.stripe_publishable_key = Rails.application.credentials.dig(:stripe, :publishable_key) || ENV["STRIPE_PUBLISHABLE_KEY"]
