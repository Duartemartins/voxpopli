class ApiKey < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

  before_create :generate_key

  attr_accessor :raw_key

  def self.authenticate(token)
    return nil unless token.present?
    prefix = token[0..15]
    api_key = find_by(key_prefix: prefix)
    return nil unless api_key
    BCrypt::Password.new(api_key.key_digest) == token ? api_key : nil
  end

  def increment_usage!
    increment!(:requests_count)
    touch(:last_used_at)
  end

  def rate_limit_exceeded?
    requests_count >= rate_limit
  end

  private

  def generate_key
    self.raw_key = "bb_live_#{SecureRandom.hex(24)}"
    self.key_prefix = raw_key[0..15]
    self.key_digest = BCrypt::Password.create(raw_key)
  end
end
