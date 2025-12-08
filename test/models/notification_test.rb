require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "valid notification" do
    notification = Notification.new(
      user: users(:alice),
      actor: users(:bob),
      notifiable: posts(:alice_post),
      action: "voted"
    )
    assert notification.valid?
  end

  test "requires user" do
    notification = Notification.new(
      actor: users(:bob),
      notifiable: posts(:alice_post),
      action: "voted"
    )
    assert_not notification.valid?
  end

  test "requires actor" do
    notification = Notification.new(
      user: users(:alice),
      notifiable: posts(:alice_post),
      action: "voted"
    )
    assert_not notification.valid?
  end

  test "requires notifiable" do
    notification = Notification.new(
      user: users(:alice),
      actor: users(:bob),
      action: "voted"
    )
    assert_not notification.valid?
  end

  test "scope unread returns only unread notifications" do
    unread = Notification.unread
    unread.each do |notification|
      assert_equal false, notification.read
    end
  end

  test "scope recent returns limited recent notifications" do
    recent = Notification.recent
    assert recent.count <= 50

    if recent.count > 1
      assert recent.first.created_at >= recent.last.created_at
    end
  end

  test "mark_as_read! updates read to true" do
    notification = notifications(:vote_notification)
    assert_not notification.read

    notification.mark_as_read!

    notification.reload
    assert notification.read
  end

  test "polymorphic association works with different types" do
    # Notification for a post
    post_notification = notifications(:vote_notification)
    assert_instance_of Post, post_notification.notifiable

    # Notification for a follow
    follow_notification = notifications(:follow_notification)
    assert_instance_of Follow, follow_notification.notifiable
  end
end
