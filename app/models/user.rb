class User < ApplicationRecord
  RESERVED_USERNAMES = %w[admin api www app mail ftp ssh root user users
                          account accounts settings profile profiles
                          login logout signup register auth oauth
                          help support contact about terms privacy].freeze

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

  validates :username, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, underscores" },
            length: { minimum: 3, maximum: 20 },
            exclusion: { in: RESERVED_USERNAMES, message: "is reserved" }

  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
            message: "must be a valid URL" }, allow_blank: true
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
            message: "must be a valid URL" }, allow_blank: true

  normalizes :username, with: ->(u) { u.strip.downcase }
  normalizes :email, with: ->(e) { e.strip.downcase }

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
end
