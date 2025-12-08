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
end
