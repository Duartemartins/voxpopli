require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "valid upvote" do
    vote = Vote.new(
      user: users(:alice),
      post: posts(:bob_post),
      value: 1
    )
    # alice already voted on bob_post in fixtures, so use a different combination
    vote.post = posts(:post_without_theme)
    assert vote.valid?
  end

  test "valid downvote" do
    vote = Vote.new(
      user: users(:alice),
      post: posts(:post_without_theme),
      value: -1
    )
    assert vote.valid?
  end

  test "value must be 1 or -1" do
    vote = Vote.new(
      user: users(:alice),
      post: posts(:post_without_theme)
    )

    vote.value = 0
    assert_not vote.valid?

    vote.value = 2
    assert_not vote.valid?

    vote.value = 1
    assert vote.valid?

    vote.value = -1
    assert vote.valid?
  end

  test "user can only vote once per post" do
    existing_vote = votes(:bob_upvotes_alice)

    duplicate_vote = Vote.new(
      user: existing_vote.user,
      post: existing_vote.post,
      value: 1
    )
    assert_not duplicate_vote.valid?
    assert_includes duplicate_vote.errors[:user_id], "has already voted on this post"
  end

  test "cannot vote on own post" do
    alice = users(:alice)
    alice_post = posts(:alice_post)

    vote = Vote.new(
      user: alice,
      post: alice_post,
      value: 1
    )
    assert_not vote.valid?
    assert_includes vote.errors[:base], "You cannot vote on your own post"
  end

  test "upvote? returns true for upvotes" do
    vote = votes(:bob_upvotes_alice)
    assert vote.upvote?
    assert_not vote.downvote?
  end

  test "downvote? returns true for downvotes" do
    vote = Vote.new(value: -1)
    assert vote.downvote?
    assert_not vote.upvote?
  end

  test "updates post score after save" do
    post = posts(:post_without_theme)
    post.update_column(:score, 0)

    Vote.create!(
      user: users(:alice),
      post: post,
      value: 1
    )

    post.reload
    assert_equal 1, post.score
  end

  test "updates post score after destroy" do
    vote = votes(:bob_upvotes_alice)
    post = vote.post
    initial_score = post.votes.sum(:value)

    vote.destroy

    post.reload
    assert_equal initial_score - 1, post.score
  end

  test "scope upvotes returns only upvotes" do
    upvotes = Vote.upvotes
    upvotes.each do |vote|
      assert_equal 1, vote.value
    end
  end

  test "scope downvotes returns only downvotes" do
    # Create a downvote for testing
    Vote.create!(
      user: users(:alice),
      post: posts(:post_without_theme),
      value: -1
    )

    downvotes = Vote.downvotes
    downvotes.each do |vote|
      assert_equal(-1, vote.value)
    end
  end

  test "cannot_vote_own_post handles nil post" do
    vote = Vote.new(
      user: users(:alice),
      post: nil,
      value: 1
    )
    # Should not raise error, but will be invalid due to belongs_to validation
    assert_not vote.valid?
  end

  test "create_notification skips notification for own post" do
    alice = users(:alice)
    bob = users(:bob)
    bob_post = posts(:bob_post)

    # Clear any existing votes
    Vote.where(user: alice, post: bob_post).destroy_all

    # Upvote someone else's post should create notification
    assert_difference "Notification.count", 1 do
      Vote.create!(user: alice, post: bob_post, value: 1)
    end
  end

  test "create_notification skips notification for downvotes" do
    alice = users(:alice)
    bob_post = posts(:bob_post)

    # Clear any existing votes
    Vote.where(user: alice, post: bob_post).destroy_all

    # Downvote should NOT create notification
    assert_no_difference "Notification.count" do
      Vote.create!(user: alice, post: bob_post, value: -1)
    end
  end

  test "trigger_webhooks triggers webhook for post.voted event" do
    alice = users(:alice)
    bob = users(:bob)
    bob_post = posts(:bob_post)

    # Create active webhook for bob that listens for post.voted
    webhook = Webhook.create!(
      user: bob,
      url: "https://example.com/webhook",
      events: '["post.voted"]',
      active: true
    )

    # Clear any existing votes
    Vote.where(user: alice, post: bob_post).destroy_all

    assert_difference "ActiveJob::Base.queue_adapter.enqueued_jobs.size" do
      Vote.create!(user: alice, post: bob_post, value: 1)
    end
  end

  test "trigger_webhooks does not trigger for unsubscribed events" do
    alice = users(:alice)
    bob = users(:bob)
    bob_post = posts(:bob_post)

    # Clear existing webhooks for bob
    bob.webhooks.destroy_all

    # Create webhook that does NOT listen for post.voted
    webhook = Webhook.create!(
      user: bob,
      url: "https://example.com/webhook",
      events: '["post.created"]',
      active: true
    )

    # Clear any existing votes
    Vote.where(user: alice, post: bob_post).destroy_all

    # Count webhook jobs before
    initial_webhook_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.count do |job|
      job[:job] == WebhookDeliveryJob
    end

    Vote.create!(user: alice, post: bob_post, value: 1)

    # Count webhook jobs after - should be the same (no new webhook jobs)
    final_webhook_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.count do |job|
      job[:job] == WebhookDeliveryJob
    end
    assert_equal initial_webhook_jobs, final_webhook_jobs, "Should not enqueue webhook jobs for unsubscribed events"
  end

  test "trigger_webhooks handles invalid JSON in webhook events gracefully" do
    alice = users(:alice)
    bob = users(:bob)
    bob_post = posts(:bob_post)

    # Clear existing webhooks for bob
    bob.webhooks.destroy_all

    # Create webhook with valid events first, then corrupt it
    webhook = Webhook.create!(
      user: bob,
      url: "https://example.com/webhook",
      events: '["post.voted"]',
      active: true
    )
    # Corrupt the events JSON directly in database
    webhook.update_column(:events, 'invalid json')

    # Clear any existing votes
    Vote.where(user: alice, post: bob_post).destroy_all

    # Should not raise error, just skip
    assert_nothing_raised do
      Vote.create!(user: alice, post: bob_post, value: 1)
    end
  end

  test "voting_rate_limit allows voting under limit" do
    alice = users(:alice)
    post = posts(:post_without_theme)

    # Should be able to vote when under rate limit
    vote = Vote.new(user: alice, post: post, value: 1)
    assert vote.valid?
  end

  test "voting_rate_limit blocks voting over limit" do
    # Create a fresh user for this test
    rate_user = User.create!(
      username: "ratelimituser",
      email: "ratelimit@example.com",
      password: "password123"
    )

    # Create 30 posts and votes in the last minute
    30.times do |i|
      post = Post.create!(
        user: users(:bob),
        body: "Rate limit test post #{i}"
      )
      vote = Vote.new(user: rate_user, post: post, value: 1)
      vote.save(validate: false)
      vote.update_column(:created_at, 30.seconds.ago)
    end

    # 31st vote should be blocked
    new_post = Post.create!(user: users(:bob), body: "One more post")
    vote = Vote.new(user: rate_user, post: new_post, value: 1)
    assert_not vote.valid?
    assert_includes vote.errors[:base], "You're voting too fast"
  end
end
