require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "valid payment" do
    payment = Payment.new(
      user: @user,
      amount_cents: 500,
      currency: "usd",
      status: "pending"
    )
    assert payment.valid?
  end

  test "requires user" do
    payment = Payment.new(amount_cents: 500, currency: "usd", status: "pending")
    assert_not payment.valid?
    assert_includes payment.errors[:user], "must exist"
  end

  test "requires amount_cents" do
    payment = Payment.new(user: @user, currency: "usd", status: "pending")
    payment.amount_cents = nil
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "can't be blank"
  end

  test "requires amount_cents greater than 0" do
    payment = Payment.new(user: @user, amount_cents: 0, currency: "usd", status: "pending")
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than 0"
  end

  test "requires currency" do
    payment = Payment.new(user: @user, amount_cents: 500, status: "pending")
    payment.currency = nil
    assert_not payment.valid?
    assert_includes payment.errors[:currency], "can't be blank"
  end

  test "requires status" do
    payment = Payment.new(user: @user, amount_cents: 500, currency: "usd")
    payment.status = nil
    assert_not payment.valid?
    assert_includes payment.errors[:status], "can't be blank"
  end

  test "status must be valid" do
    payment = Payment.new(user: @user, amount_cents: 500, currency: "usd", status: "invalid")
    assert_not payment.valid?
    assert_includes payment.errors[:status], "is not included in the list"
  end

  test "valid statuses" do
    %w[pending completed failed refunded].each do |status|
      payment = Payment.new(user: @user, amount_cents: 500, currency: "usd", status: status)
      assert payment.valid?, "#{status} should be valid"
    end
  end

  test "stripe_session_id uniqueness" do
    payment1 = Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "pending", stripe_session_id: "cs_123")
    payment2 = Payment.new(user: users(:bob), amount_cents: 500, currency: "usd", status: "pending", stripe_session_id: "cs_123")
    assert_not payment2.valid?
    assert_includes payment2.errors[:stripe_session_id], "has already been taken"
  end

  test "stripe_payment_id uniqueness" do
    payment1 = Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "pending", stripe_payment_id: "pi_123")
    payment2 = Payment.new(user: users(:bob), amount_cents: 500, currency: "usd", status: "pending", stripe_payment_id: "pi_123")
    assert_not payment2.valid?
    assert_includes payment2.errors[:stripe_payment_id], "has already been taken"
  end

  test "allows nil stripe_session_id" do
    payment = Payment.new(user: @user, amount_cents: 500, currency: "usd", status: "pending", stripe_session_id: nil)
    assert payment.valid?
  end

  test "completed? returns true for completed status" do
    payment = Payment.new(status: "completed")
    assert payment.completed?
  end

  test "completed? returns false for non-completed status" do
    payment = Payment.new(status: "pending")
    assert_not payment.completed?
  end

  test "pending? returns true for pending status" do
    payment = Payment.new(status: "pending")
    assert payment.pending?
  end

  test "pending? returns false for non-pending status" do
    payment = Payment.new(status: "completed")
    assert_not payment.pending?
  end

  test "complete! updates status and payment_id" do
    payment = Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "pending")
    payment.complete!(stripe_payment_id: "pi_123")

    payment.reload
    assert payment.completed?
    assert_equal "pi_123", payment.stripe_payment_id
  end

  test "complete! updates user payment_method and paid_at" do
    payment = Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "pending")
    payment.complete!(stripe_payment_id: "pi_123")

    @user.reload
    assert_equal "stripe", @user.payment_method
    assert_not_nil @user.paid_at
  end

  test "fail! updates status to failed" do
    payment = Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "pending")
    payment.fail!

    payment.reload
    assert_equal "failed", payment.status
  end

  test "create_for_registration! creates payment with correct values" do
    payment = Payment.create_for_registration!(user: @user, stripe_session_id: "cs_test123")

    assert_equal @user, payment.user
    assert_equal Payment::REGISTRATION_AMOUNT_CENTS, payment.amount_cents
    assert_equal Payment::REGISTRATION_CURRENCY, payment.currency
    assert_equal "cs_test123", payment.stripe_session_id
    assert_equal "pending", payment.status
    assert_equal "stripe", payment.payment_method
  end

  test "amount_dollars returns correct value" do
    payment = Payment.new(amount_cents: 500)
    assert_equal 5.0, payment.amount_dollars
  end

  test "display_amount returns formatted amount" do
    payment = Payment.new(amount_cents: 500, currency: "usd")
    assert_equal "$5.00 USD", payment.display_amount
  end

  test "scope completed returns only completed payments" do
    Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "completed")
    Payment.create!(user: users(:bob), amount_cents: 500, currency: "usd", status: "pending")

    completed = Payment.completed
    assert completed.all?(&:completed?)
  end

  test "scope pending returns only pending payments" do
    Payment.create!(user: @user, amount_cents: 500, currency: "usd", status: "completed")
    Payment.create!(user: users(:bob), amount_cents: 500, currency: "usd", status: "pending")

    pending = Payment.pending
    assert pending.all?(&:pending?)
  end

  test "scope for_registration returns payments with registration amount" do
    Payment.create!(user: @user, amount_cents: Payment::REGISTRATION_AMOUNT_CENTS, currency: "usd", status: "pending")
    Payment.create!(user: users(:bob), amount_cents: 1000, currency: "usd", status: "pending")

    registration_payments = Payment.for_registration
    assert registration_payments.all? { |p| p.amount_cents == Payment::REGISTRATION_AMOUNT_CENTS }
  end

  test "REGISTRATION_AMOUNT_CENTS constant" do
    assert_equal 500, Payment::REGISTRATION_AMOUNT_CENTS
  end

  test "REGISTRATION_CURRENCY constant" do
    assert_equal "usd", Payment::REGISTRATION_CURRENCY
  end

  test "STATUSES constant includes all valid statuses" do
    assert_equal %w[pending completed failed refunded], Payment::STATUSES
  end
end
