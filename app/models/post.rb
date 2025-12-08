class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :theme, counter_cache: true, optional: true
  belongs_to :parent, class_name: 'Post', optional: true, counter_cache: :replies_count
  belongs_to :repost_of, class_name: 'Post', optional: true, counter_cache: :reposts_count

  has_many :replies, class_name: 'Post', foreign_key: :parent_id, dependent: :destroy
  has_many :reposts, class_name: 'Post', foreign_key: :repost_of_id, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :voters, through: :votes, source: :user
  has_many :bookmarks, dependent: :destroy

  validates :body, presence: true

  scope :by_new, -> { order(created_at: :desc) }
  scope :by_voted, -> { order(score: :desc, created_at: :desc) }
  scope :original, -> { where(parent_id: nil, repost_of_id: nil) }
  scope :for_theme, ->(theme) { where(theme: theme) if theme.present? }

  after_create_commit :notify_mentions
  after_create_commit :trigger_webhooks

  def reply?
    parent_id.present?
  end

  def repost?
    repost_of_id.present?
  end

  def voted_by?(user)
    return false unless user
    votes.exists?(user: user)
  end

  def vote_value_by(user)
    return 0 unless user
    votes.find_by(user: user)&.value || 0
  end

  def recalculate_score!
    update_column(:score, votes.sum(:value))
  end

  private

  def notify_mentions
    mentioned_usernames = body.scan(/@([a-z0-9_]+)/i).flatten.uniq
    User.where(username: mentioned_usernames).find_each do |mentioned_user|
      next if mentioned_user == user
      Notification.create!(
        user: mentioned_user,
        actor: user,
        notifiable: self,
        action: 'mentioned'
      )
    end
  end

  def trigger_webhooks
    user.webhooks.active.each do |webhook|
      events = JSON.parse(webhook.events) rescue []
      if events.include?('post.created')
        WebhookDeliveryJob.perform_later(webhook.id, 'post.created', as_json)
      end
    end
  end
end
