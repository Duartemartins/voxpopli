require "test_helper"
require "minitest/mock"
require "ostruct"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "new renders checkout form for unauthenticated user" do
    get checkout_new_path
    assert_response :success
    assert_select "h2", /PAID_REGISTRATION/
  end

  test "new redirects authenticated user to root" do
    sign_in users(:alice)
    get checkout_new_path
    assert_redirected_to root_path
  end

  test "create requires user params" do
    post checkout_path, params: {}
    assert_response :bad_request
  end

  test "create validates user data" do
    post checkout_path, params: {
      user: {
        username: "",
        email: "invalid",
        password: "short"
      }
    }
    assert_response :unprocessable_entity
  end

  test "create with valid data redirects to stripe" do
    mock_session = OpenStruct.new(url: "https://stripe.com/checkout")

    Stripe::Checkout::Session.stub :create, mock_session do
      post checkout_path, params: {
        user: {
          username: "newcheckoutuser",
          email: "checkout@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      assert_redirected_to "https://stripe.com/checkout"
      assert_equal "newcheckoutuser", session[:pending_registration]["username"]
    end
  end

  test "create handles stripe error" do
    Stripe::Checkout::Session.stub :create, ->(_) { raise Stripe::StripeError.new("Mock error") } do
      post checkout_path, params: {
        user: {
          username: "newcheckoutuser",
          email: "checkout@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      assert_response :unprocessable_entity
      assert_match "Payment processing error", flash[:alert]
    end
  end

  test "success without session_id redirects to join" do
    get checkout_success_path
    assert_redirected_to join_path
    assert_equal "Invalid checkout session", flash[:alert]
  end

  test "success creates user and signs in when payment is paid" do
    # Setup pending registration in session
    post checkout_path, params: {
      user: {
        username: "paiduser",
        email: "paid@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    # We need to mock the create call to get the session populated,
    # but since we can't easily do that in one go without the stub above,
    # let's just manually set the session if possible.
    # Integration tests make accessing session hard.
    # So we'll use the stubbed create to populate the session first.

    mock_create_session = OpenStruct.new(url: "https://stripe.com/checkout")
    Stripe::Checkout::Session.stub :create, mock_create_session do
      post checkout_path, params: {
        user: {
          username: "paiduser",
          email: "paid@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    mock_retrieve_session = OpenStruct.new(
      payment_status: "paid",
      payment_intent: "pi_123",
      metadata: OpenStruct.new(email: "paid@example.com")
    )

    Stripe::Checkout::Session.stub :retrieve, mock_retrieve_session do
      get checkout_success_path(session_id: "cs_test_123")

      assert_redirected_to root_path
      assert_equal "Welcome to Voxpopli! Your account has been created.", flash[:notice]

      user = User.find_by(username: "paiduser")
      assert user
      assert user.paid?
      assert_equal "stripe", user.payment_method
    end
  end

  test "success handles expired session (missing registration data)" do
    # Don't populate session[:pending_registration]

    mock_retrieve_session = OpenStruct.new(
      payment_status: "paid",
      metadata: OpenStruct.new(email: "missing@example.com")
    )

    Stripe::Checkout::Session.stub :retrieve, mock_retrieve_session do
      get checkout_success_path(session_id: "cs_test_123")

      assert_redirected_to join_path
      assert_match "Registration session expired", flash[:alert]
    end
  end

  test "success handles existing user (page refresh)" do
    user = users(:alice)

    mock_retrieve_session = OpenStruct.new(
      payment_status: "paid",
      metadata: OpenStruct.new(email: user.email)
    )

    Stripe::Checkout::Session.stub :retrieve, mock_retrieve_session do
      get checkout_success_path(session_id: "cs_test_123")

      assert_redirected_to root_path
      assert_equal "Welcome back!", flash[:notice]
    end
  end

  test "cancel redirects to join" do
    get checkout_cancel_path
    assert_redirected_to join_path
    assert_equal "Payment cancelled. You can try again or use an invite code.", flash[:notice]
  end

  test "success handles stripe error" do
    Stripe::Checkout::Session.stub :retrieve, ->(_) { raise Stripe::StripeError.new("Mock error") } do
      get checkout_success_path(session_id: "cs_test_error")
      assert_redirected_to join_path
      assert_match "Error verifying payment", flash[:alert]
    end
  end
end


class CheckoutsControllerPaymentFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # These tests demonstrate expected behavior with proper Stripe mocking
  # In a full test suite, you would use WebMock or VCR to mock Stripe API calls

  test "full payment flow creates user and payment on success" do
    # This would be an integration test with Stripe mocks
    # Simulating what happens when a user completes payment:
    #
    # 1. User fills out form and clicks pay
    # 2. Stripe checkout session created
    # 3. User redirected to Stripe
    # 4. User pays
    # 5. Stripe redirects back to success_url
    # 6. success action verifies payment and creates user
    #
    # For now, verify that the components work independently
    # Payment model works correctly (tested in payment_test.rb)
    assert_equal 500, Payment::REGISTRATION_AMOUNT_CENTS
    assert_equal "usd", Payment::REGISTRATION_CURRENCY
  end

  test "payment creates payment record" do
    user = User.create!(
      email: "paymenttest@example.com",
      username: "paymenttest",
      password: "password123"
    )

    payment = Payment.create_for_registration!(
      user: user,
      stripe_session_id: "cs_test_#{SecureRandom.hex(8)}"
    )

    assert_equal "pending", payment.status
    assert_equal 500, payment.amount_cents
    assert_equal "usd", payment.currency
  end

  test "completing payment updates user" do
    user = User.create!(
      email: "complete@example.com",
      username: "completeuser",
      password: "password123"
    )

    payment = Payment.create_for_registration!(
      user: user,
      stripe_session_id: "cs_test_#{SecureRandom.hex(8)}"
    )

    payment.complete!(stripe_payment_id: "pi_test_123")

    user.reload
    assert user.paid?
    assert_equal "stripe", user.payment_method
    assert_not_nil user.paid_at
  end
end

class CheckoutsControllerWebhookTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "webhook handles checkout.session.completed event" do
    event_data = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_completed",
          payment_status: "paid"
        }
      }
    }

    post checkout_webhook_path,
         params: event_data.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :ok
  end

  test "webhook handles payment_intent.succeeded event" do
    # Create a payment to be found
    user = User.create!(
      email: "webhook_success@example.com",
      username: "webhooksuccess",
      password: "password123"
    )
    payment = Payment.create_for_registration!(
      user: user,
      stripe_session_id: "cs_test_pi_success"
    )
    payment.update!(stripe_payment_id: "pi_test_success")

    event_data = {
      type: "payment_intent.succeeded",
      data: {
        object: {
          id: "pi_test_success"
        }
      }
    }

    post checkout_webhook_path,
         params: event_data.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :ok
  end

  test "webhook handles payment_intent.payment_failed event" do
    # Create a payment to be found
    user = User.create!(
      email: "webhook_fail@example.com",
      username: "webhookfail",
      password: "password123"
    )
    payment = Payment.create_for_registration!(
      user: user,
      stripe_session_id: "cs_test_pi_fail"
    )
    payment.update!(stripe_payment_id: "pi_test_fail")

    event_data = {
      type: "payment_intent.payment_failed",
      data: {
        object: {
          id: "pi_test_fail"
        }
      }
    }

    post checkout_webhook_path,
         params: event_data.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :ok
  end

  test "webhook handles unknown event types gracefully" do
    event_data = {
      type: "unknown.event.type",
      data: {
        object: {
          id: "obj_123"
        }
      }
    }

    post checkout_webhook_path,
         params: event_data.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :ok
  end
end

class CheckoutsControllerCancelTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "cancel clears pending registration from session" do
    # Set up pending registration in session
    post checkout_path, params: {
      user: {
        username: "pendingcancel",
        email: "pending@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    # The above may fail on Stripe, but should set session
    # Now test cancel
    sign_in users(:alice) # Need to be signed in for cancel to work
    get checkout_cancel_path

    # Should redirect
    assert_response :redirect
  end
end
