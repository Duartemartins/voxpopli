class User < ApplicationRecord
  RESERVED_USERNAMES = %w[admin api www app mail ftp ssh root user users
                          account accounts settings profile profiles
                          login logout signup register auth oauth
                          help support contact about terms privacy
                          directory builders].freeze

  LOOKING_FOR_OPTIONS = %w[cofounders beta_testers feedback investors hiring nothing].freeze

  # Virtual attributes for registration
  attr_accessor :invite_code, :website_url

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :post
  has_many :notifications, dependent: :destroy
  has_many :notifications_as_actor, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_one :invite_used, class_name: "Invite", foreign_key: :invitee_id, dependent: :nullify
  has_many :invites_sent, class_name: "Invite", foreign_key: :inviter_id, dependent: :destroy

  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  has_one_attached :avatar

  # Scopes for directory
  scope :recently_active, -> { order(updated_at: :desc) }
  scope :newest, -> { order(created_at: :desc) }
  scope :with_complete_profile, -> { where.not(tagline: [ nil, "" ]).where.not(website: [ nil, "" ]) }
  scope :with_skill, ->(skill) { where("skills LIKE ?", "%\"#{skill}\"%") }
  scope :looking_for_type, ->(type) { where(looking_for: type) }

  validates :username, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, underscores" },
            length: { minimum: 3, maximum: 20 },
            exclusion: { in: RESERVED_USERNAMES, message: "is reserved" }

  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
            message: "must be a valid URL" }, allow_blank: true

  validates :tagline, length: { maximum: 140 }, allow_blank: true

  validates :github_username, uniqueness: { case_sensitive: false }, allow_blank: true,
            format: { with: /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i,
            message: "must be a valid GitHub username" }

  validates :looking_for, inclusion: { in: LOOKING_FOR_OPTIONS }, allow_blank: true

  normalizes :username, with: ->(u) { u.strip.downcase }
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :github_username, with: ->(g) { g&.strip&.gsub(/^@/, "") }

  # Serialize JSON arrays
  serialize :skills, coder: JSON
  serialize :launched_products, coder: JSON

  def to_param
    username
  end

  def follow(user)
    return if self == user || following?(user)
    following << user
  end

  def unfollow(user)
    following.delete(user)
  end

  def following?(user)
    following.include?(user)
  end

  def timeline
    Post.where(user_id: following.select(:id))
        .or(Post.where(user_id: id))
        .where(parent_id: nil)
        .includes(:user, :theme)
  end

  INVITE_CODES_LIMIT = 5

  def invite_codes
    invites_sent.order(:created_at)
  end

  def generate_invite_codes!
    remaining = INVITE_CODES_LIMIT - invites_sent.count
    remaining.times { invites_sent.create! }
  end

  def ensure_invite_codes!
    generate_invite_codes! if invites_sent.count < INVITE_CODES_LIMIT
    invite_codes
  end

  # Builder profile helpers
  def skills_list
    skills || []
  end

  def skills_list=(value)
    self.skills = value.is_a?(String) ? value.split(",").map(&:strip).reject(&:blank?) : value
  end

  def launched_products_list
    launched_products || []
  end

  def add_launched_product(name:, url:, description: nil, mrr: nil, revenue_confirmed: false)
    self.launched_products ||= []
    self.launched_products << {
      name: name,
      url: url,
      description: description,
      mrr: mrr,
      revenue_confirmed: revenue_confirmed
    }
  end

  def has_complete_builder_profile?
    tagline.present? && website.present?
  end

  def github_url
    "https://github.com/#{github_username}" if github_username.present?
  end

  def looking_for_display
    return nil if looking_for.blank?
    looking_for.titleize.gsub("_", " ")
  end

  # JSON-LD structured data for SEO
  def to_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => display_name || username,
      "alternateName" => username,
      "url" => Rails.application.routes.url_helpers.directory_user_url(username, host: Rails.application.config.action_mailer.default_url_options[:host] || "localhost"),
      "description" => tagline || bio,
      "sameAs" => [
        website,
        github_url
      ].compact
    }.compact
  end
end
