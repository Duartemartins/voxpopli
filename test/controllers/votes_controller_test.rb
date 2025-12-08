require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @post = posts(:post_without_theme)  # Post by charlie, alice can vote
  end

  test "create requires authentication" do
    post post_vote_path(@post), params: { value: 1 }
    assert_redirected_to new_user_session_path
  end

  test "create upvote" do
    sign_in @user

    assert_difference "Vote.count", 1 do
      post post_vote_path(@post), params: { value: 1 }
    end

    vote = Vote.last
    assert_equal 1, vote.value
    assert_equal @user, vote.user
  end

  test "create downvote" do
    sign_in @user

    assert_difference "Vote.count", 1 do
      post post_vote_path(@post), params: { value: -1 }
    end

    vote = @post.votes.find_by(user: @user)
    assert_equal(-1, vote.value)
  end

  test "invalid value defaults to upvote" do
    sign_in @user

    post post_vote_path(@post), params: { value: 5 }

    vote = Vote.last
    assert_equal 1, vote.value
  end

  test "toggle vote removes when same value" do
    sign_in @user

    # First vote
    post post_vote_path(@post), params: { value: 1 }
    assert_equal 1, @post.votes.count

    # Same vote again removes it
    assert_difference "Vote.count", -1 do
      post post_vote_path(@post), params: { value: 1 }
    end
  end

  test "change vote value" do
    sign_in @user

    # First upvote
    post post_vote_path(@post), params: { value: 1 }
    vote = Vote.find_by(user: @user, post: @post)
    assert_equal 1, vote.value

    # Change to downvote
    post post_vote_path(@post), params: { value: -1 }
    vote.reload
    assert_equal(-1, vote.value)
  end

  test "destroy removes vote" do
    sign_in @user

    # Create a vote first
    post post_vote_path(@post), params: { value: 1 }

    assert_difference "Vote.count", -1 do
      delete post_vote_path(@post)
    end
  end

  test "destroy with no existing vote" do
    sign_in @user

    assert_no_difference "Vote.count" do
      delete post_vote_path(@post)
    end

    assert_redirected_to timeline_path
  end

  test "create responds to turbo_stream" do
    sign_in @user

    post post_vote_path(@post), params: { value: 1 }, as: :turbo_stream
    assert_response :success
  end
end
