class Payment < ApplicationRecord
  REGISTRATION_AMOUNT_CENTS = 500
  REGISTRATION_CURRENCY = "usd".freeze

  STATUSES = %w[pending completed failed refunded].freeze

  belongs_to :user

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :stripe_session_id, uniqueness: true, allow_nil: true
  validates :stripe_payment_id, uniqueness: true, allow_nil: true

  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :for_registration, -> { where(amount_cents: REGISTRATION_AMOUNT_CENTS) }

  def completed?
    status == "completed"
  end

  def pending?
    status == "pending"
  end

  def complete!(stripe_payment_id: nil)
    update!(
      status: "completed",
      stripe_payment_id: stripe_payment_id
    )
    user.update!(payment_method: "stripe", paid_at: Time.current)
  end

  def fail!
    update!(status: "failed")
  end

  def self.create_for_registration!(user:, stripe_session_id:)
    create!(
      user: user,
      amount_cents: REGISTRATION_AMOUNT_CENTS,
      currency: REGISTRATION_CURRENCY,
      stripe_session_id: stripe_session_id,
      status: "pending",
      payment_method: "stripe"
    )
  end

  def amount_dollars
    amount_cents / 100.0
  end

  def display_amount
    "$#{'%.2f' % amount_dollars} #{currency.upcase}"
  end
end
