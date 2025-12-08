class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def mark_as_read!
    update!(read: true)
  end
end
