class Webhook < ApplicationRecord
  belongs_to :user

  EVENTS = %w[post.created post.voted user.followed].freeze

  encrypts :secret

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]) }
  validate :validate_events

  before_create :generate_secret

  scope :active, -> { where(active: true) }

  def events_list
    JSON.parse(events) rescue []
  end

  def events_list=(arr)
    self.events = arr.to_json
  end

  private

  def generate_secret
    self.secret = SecureRandom.hex(32)
  end

  def validate_events
    parsed = JSON.parse(events) rescue []
    errors.add(:events, "must be present") if parsed.empty?
    invalid = parsed - EVENTS
    errors.add(:events, "contains invalid events: #{invalid.join(', ')}") if invalid.any?
  end
end
