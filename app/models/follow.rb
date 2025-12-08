class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  after_create_commit :create_notification

  private

  def cannot_follow_self
    errors.add(:base, "You cannot follow yourself") if follower_id == followed_id
  end

  def create_notification
    Notification.create!(
      user: followed,
      actor: follower,
      notifiable: self,
      action: "followed"
    )
  end
end
