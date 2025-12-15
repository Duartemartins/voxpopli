class Invite < ApplicationRecord
  belongs_to :inviter, class_name: "User", optional: true
  belongs_to :invitee, class_name: "User", optional: true

  validates :code, presence: true, uniqueness: true
  validate :not_expired, on: :use

  before_validation :generate_code, on: :create
  before_validation :set_default_expiry, on: :create

  scope :available, -> { where(used_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ? AND used_at IS NULL", Time.current) }

  def available?
    used_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def used?
    used_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current && !used?
  end

  def days_until_expiry
    return nil if expires_at.nil?
    return 0 if expired?
    ((expires_at - Time.current) / 1.day).ceil
  end

  def use!(user)
    raise "Invite already used" unless available?

    transaction do
      update!(invitee: user, used_at: Time.current)
      # Set the invited_by relationship on the user
      user.update!(invited_by: inviter) if inviter.present?
    end
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(12).upcase
  end

  def set_default_expiry
    self.expires_at ||= User::INVITE_CODE_EXPIRY_DAYS.days.from_now if inviter.present?
  end

  def not_expired
    errors.add(:base, "Invite has expired") if expires_at.present? && expires_at <= Time.current
    errors.add(:base, "Invite has already been used") if used_at.present?
  end
end
