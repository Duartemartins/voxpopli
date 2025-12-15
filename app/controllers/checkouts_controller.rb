require "ostruct"

class CheckoutsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :webhook ]
  before_action :authenticate_user!, except: [ :webhook, :new, :create, :success, :cancel ]

  # GET /checkout/new - Show registration payment page
  def new
    if user_signed_in?
      redirect_to root_path, notice: "You are already registered"
      nil
    end
  end

  # POST /checkout - Create Stripe checkout session for registration
  def create
    # Store registration data in session for after payment
    session[:pending_registration] = registration_params.to_h

    # Validate registration data
    temp_user = User.new(registration_params.except(:invite_code, :website_url))
    unless temp_user.valid?
      flash[:alert] = temp_user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
      return
    end

    begin
      checkout_session = Stripe::Checkout::Session.create({
        payment_method_types: [ "card" ],
        line_items: [ {
          price_data: {
            currency: Payment::REGISTRATION_CURRENCY,
            product_data: {
              name: "Voxpopli Registration",
              description: "One-time registration fee for lifetime access"
            },
            unit_amount: Payment::REGISTRATION_AMOUNT_CENTS
          },
          quantity: 1
        } ],
        mode: "payment",
        success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: checkout_cancel_url,
        metadata: {
          email: registration_params[:email],
          username: registration_params[:username]
        }
      })

      redirect_to checkout_session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      flash[:alert] = "Payment processing error. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /checkout/success - Handle successful payment
  def success
    session_id = params[:session_id]

    unless session_id
      redirect_to join_path, alert: "Invalid checkout session"
      return
    end

    begin
      checkout_session = Stripe::Checkout::Session.retrieve(session_id)

      if checkout_session.payment_status == "paid"
        # Create user from stored registration data
        registration_data = session.delete(:pending_registration)

        if registration_data.blank?
          # Check if user already exists (maybe page was refreshed)
          existing_user = User.find_by(email: checkout_session.metadata.email)
          if existing_user
            sign_in(existing_user)
            redirect_to root_path, notice: "Welcome back!"
            return
          else
            redirect_to join_path, alert: "Registration session expired. Please try again."
            return
          end
        end

        user = User.new(registration_data.symbolize_keys.except(:invite_code, :website_url))
        user.payment_method = "stripe"
        user.paid_at = Time.current

        if user.save
          # Create payment record
          Payment.create_for_registration!(
            user: user,
            stripe_session_id: session_id
          ).complete!(stripe_payment_id: checkout_session.payment_intent)

          sign_in(user)
          redirect_to root_path, notice: "Welcome to Voxpopli! Your account has been created."
        else
          redirect_to join_path, alert: "Registration failed: #{user.errors.full_messages.join(', ')}"
        end
      else
        redirect_to join_path, alert: "Payment was not completed. Please try again."
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error on success: #{e.message}"
      redirect_to join_path, alert: "Error verifying payment. Please contact support."
    end
  end

  # GET /checkout/cancel - Handle cancelled payment
  def cancel
    session.delete(:pending_registration)
    redirect_to join_path, notice: "Payment cancelled. You can try again or use an invite code."
  end

  # POST /checkout/webhook - Handle Stripe webhooks
  def webhook
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = Rails.application.config.stripe_webhook_secret

    begin
      event = if webhook_secret.present?
        Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
      else
        # For development without webhook secret
        JSON.parse(payload, object_class: OpenStruct)
      end

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "payment_intent.succeeded"
        handle_payment_succeeded(event.data.object)
      when "payment_intent.payment_failed"
        handle_payment_failed(event.data.object)
      end

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error "Webhook JSON parse error: #{e.message}"
      head :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook signature error: #{e.message}"
      head :bad_request
    end
  end

  private

  def registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :invite_code, :website_url)
  end

  def handle_checkout_completed(session)
    Rails.logger.info "Checkout completed: #{session.id}"
    # Payment is handled in success action when user returns
  end

  def handle_payment_succeeded(payment_intent)
    Rails.logger.info "Payment succeeded: #{payment_intent.id}"
    # Update payment record if exists
    payment = Payment.find_by(stripe_payment_id: payment_intent.id)
    payment&.complete! unless payment&.completed?
  end

  def handle_payment_failed(payment_intent)
    Rails.logger.info "Payment failed: #{payment_intent.id}"
    # Mark payment as failed
    payment = Payment.find_by(stripe_payment_id: payment_intent.id)
    payment&.fail!
  end
end
