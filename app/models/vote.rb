class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :value, inclusion: { in: [ -1, 1 ] }
  validates :user_id, uniqueness: { scope: :post_id, message: "has already voted on this post" }
  validate :cannot_vote_own_post
  validate :voting_rate_limit

  after_save :update_post_score
  after_destroy :update_post_score
  after_create_commit :create_notification
  after_create_commit :trigger_webhooks
  after_create_commit :update_user_quest_progress

  scope :upvotes, -> { where(value: 1) }
  scope :downvotes, -> { where(value: -1) }

  def upvote?
    value == 1
  end

  def downvote?
    value == -1
  end

  private

  def update_user_quest_progress
    user.check_quest_completion
  end

  def cannot_vote_own_post
    errors.add(:base, "You cannot vote on your own post") if post&.user_id == user_id
  end

  def voting_rate_limit
    recent_votes = user.votes.where("created_at > ?", 1.minute.ago).count
    errors.add(:base, "You're voting too fast") if recent_votes >= 30
  end

  def update_post_score
    post.recalculate_score!
    post.update_column(:votes_count, post.votes.count)
  end

  def create_notification
    return if post.user == user
    return if downvote?
    Notification.create!(
      user: post.user,
      actor: user,
      notifiable: post,
      action: "voted"
    )
  end

  def trigger_webhooks
    post.user.webhooks.active.each do |webhook|
      events = JSON.parse(webhook.events) rescue []
      if events.include?("post.voted")
        WebhookDeliveryJob.perform_later(webhook.id, "post.voted", {
          post_id: post_id,
          voter_id: user_id,
          value: value,
          new_score: post.score
        })
      end
    end
  end
end
