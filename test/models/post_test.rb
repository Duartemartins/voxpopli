require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "valid post" do
    post = Post.new(
      body: "Test post content",
      user: users(:alice)
    )
    assert post.valid?
  end

  test "requires body" do
    post = Post.new(user: users(:alice))
    assert_not post.valid?
    assert_includes post.errors[:body], "can't be blank"
  end

  test "requires user" do
    post = Post.new(body: "Test content")
    assert_not post.valid?
  end

  test "theme is optional" do
    post = Post.new(
      body: "No theme post",
      user: users(:alice)
    )
    assert post.valid?
  end

  test "reply? returns true for replies" do
    reply = posts(:reply_to_alice)
    assert reply.reply?

    original = posts(:alice_post)
    assert_not original.reply?
  end

  test "repost? returns true for reposts" do
    post = posts(:alice_post)
    assert_not post.repost?

    repost = Post.new(
      body: "Reposting this",
      user: users(:bob),
      repost_of: post
    )
    repost.save!
    assert repost.repost?
  end

  test "voted_by? checks if user voted" do
    post = posts(:alice_post)
    bob = users(:bob)
    charlie = users(:charlie)

    # bob and charlie voted on alice_post (from fixtures)
    assert post.voted_by?(bob)
    assert post.voted_by?(charlie)

    # alice hasn't voted on her own post
    assert_not post.voted_by?(users(:alice))
  end

  test "voted_by? returns false for nil user" do
    post = posts(:alice_post)
    assert_not post.voted_by?(nil)
  end

  test "vote_value_by returns vote value" do
    post = posts(:alice_post)
    bob = users(:bob)

    assert_equal 1, post.vote_value_by(bob)
    assert_equal 0, post.vote_value_by(users(:alice))
    assert_equal 0, post.vote_value_by(nil)
  end

  test "recalculate_score! updates score from votes" do
    post = posts(:alice_post)
    # Reset score
    post.update_column(:score, 0)

    post.recalculate_score!
    post.reload

    # bob and charlie both upvoted (+1 each)
    assert_equal 2, post.score
  end

  test "scope by_new orders by created_at desc" do
    posts = Post.by_new
    assert posts.first.created_at >= posts.last.created_at
  end

  test "scope original excludes replies and reposts" do
    original_posts = Post.original
    original_posts.each do |post|
      assert_nil post.parent_id
      assert_nil post.repost_of_id
    end
  end

  test "scope for_theme filters by theme" do
    theme = themes(:build_in_public)
    themed_posts = Post.for_theme(theme)

    themed_posts.each do |post|
      assert_equal theme, post.theme
    end
  end

  test "scope for_theme returns all when nil" do
    all_posts = Post.all.count
    posts_for_nil_theme = Post.for_theme(nil).count
    assert_equal all_posts, posts_for_nil_theme
  end

  test "replies are destroyed when parent is destroyed" do
    parent = posts(:alice_post)
    _reply = posts(:reply_to_alice)

    assert_difference "Post.count", -2 do
      parent.destroy
    end
  end

  test "generates uuid on create" do
    post = Post.create!(
      body: "UUID test",
      user: users(:alice)
    )
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, post.id)
  end

  test "can attach image" do
    post = Post.new(
      body: "Post with image",
      user: users(:alice)
    )
    post.image.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    assert post.valid?
    assert post.image.attached?
  end

  test "validates image content type" do
    post = Post.new(
      body: "Post with bad image",
      user: users(:alice)
    )
    post.image.attach(
      io: StringIO.new("fake data"),
      filename: "test.exe",
      content_type: "application/octet-stream"
    )
    assert_not post.valid?
    assert_includes post.errors[:image], "must be a JPEG, PNG, GIF, or WebP"
  end

  test "validates image size" do
    post = Post.new(
      body: "Post with large image",
      user: users(:alice)
    )
    # Create a fake 6MB file
    large_data = "x" * 6.megabytes
    post.image.attach(
      io: StringIO.new(large_data),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    assert_not post.valid?
    assert_includes post.errors[:image], "must be less than 5MB"
  end

  # Notification tests
  test "notify_mentions creates notifications for mentioned users" do
    alice = users(:alice)
    bob = users(:bob)

    assert_difference "Notification.count", 1 do
      Post.create!(
        body: "Hey @#{bob.username} check this out!",
        user: alice
      )
    end

    notification = Notification.last
    assert_equal bob, notification.user
    assert_equal alice, notification.actor
    assert_equal "mentioned", notification.action
  end

  test "notify_mentions does not notify the post author" do
    alice = users(:alice)

    assert_no_difference "Notification.count" do
      Post.create!(
        body: "I'm mentioning myself @#{alice.username}",
        user: alice
      )
    end
  end

  test "notify_mentions handles multiple mentions" do
    alice = users(:alice)
    bob = users(:bob)
    charlie = users(:charlie)

    assert_difference "Notification.count", 2 do
      Post.create!(
        body: "Hey @#{bob.username} and @#{charlie.username}!",
        user: alice
      )
    end
  end

  test "notify_mentions handles duplicate mentions" do
    alice = users(:alice)
    bob = users(:bob)

    # Should only create one notification even with duplicate mentions
    assert_difference "Notification.count", 1 do
      Post.create!(
        body: "@#{bob.username} @#{bob.username} mentioned twice",
        user: alice
      )
    end
  end

  test "notify_mentions ignores non-existent usernames" do
    alice = users(:alice)

    assert_no_difference "Notification.count" do
      Post.create!(
        body: "Hey @nonexistentuser123 check this out!",
        user: alice
      )
    end
  end

  # Webhook tests
  test "trigger_webhooks queues jobs for active webhooks" do
    alice = users(:alice)
    webhook = alice.webhooks.create!(
      url: "https://example.com/webhook",
      secret: "secret123",
      events: '["post.created"]',
      active: true
    )

    assert_enqueued_with(job: WebhookDeliveryJob) do
      Post.create!(
        body: "Webhook trigger test",
        user: alice
      )
    end
  end

  test "trigger_webhooks skips inactive webhooks" do
    alice = users(:alice)
    alice.webhooks.destroy_all # Ensure no other webhooks interfere

    webhook = alice.webhooks.create!(
      url: "https://example.com/webhook",
      secret: "secret123",
      events: '["post.created"]',
      active: false
    )

    assert_no_enqueued_jobs(only: WebhookDeliveryJob) do
      Post.create!(
        body: "Inactive webhook test",
        user: alice
      )
    end
  end

  test "trigger_webhooks skips webhooks not listening to post.created" do
    alice = users(:alice)
    alice.webhooks.destroy_all # Ensure no other webhooks interfere

    webhook = alice.webhooks.create!(
      url: "https://example.com/webhook",
      secret: "secret123",
      events: '["post.voted"]',
      active: true
    )

    assert_no_enqueued_jobs(only: WebhookDeliveryJob) do
      Post.create!(
        body: "Wrong event webhook test",
        user: alice
      )
    end
  end
end
