class Invite < ApplicationRecord
  belongs_to :inviter, class_name: 'User', optional: true
  belongs_to :invitee, class_name: 'User', optional: true

  validates :code, presence: true, uniqueness: true
  validate :not_expired, on: :use

  before_validation :generate_code, on: :create

  scope :available, -> { where(used_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def available?
    used_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def use!(user)
    raise 'Invite already used' unless available?
    update!(invitee: user, used_at: Time.current)
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(12).upcase
  end

  def not_expired
    errors.add(:base, 'Invite has expired') if expires_at.present? && expires_at <= Time.current
    errors.add(:base, 'Invite has already been used') if used_at.present?
  end
end
