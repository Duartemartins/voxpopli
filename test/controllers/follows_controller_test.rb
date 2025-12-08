require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @target = users(:charlie)  # alice doesn't follow charlie
  end

  test "create requires authentication" do
    post user_follow_path(@target.username)
    assert_redirected_to new_user_session_path
  end

  test "create follow" do
    sign_in @user

    assert_difference "Follow.count", 1 do
      post user_follow_path(@target.username)
    end

    assert @user.following?(@target)
  end

  test "destroy requires authentication" do
    delete user_follow_path(@target.username)
    assert_redirected_to new_user_session_path
  end

  test "destroy unfollow" do
    sign_in @user
    @user.follow(@target)

    assert_difference "Follow.count", -1 do
      delete user_follow_path(@target.username)
    end

    assert_not @user.following?(@target)
  end

  test "create responds to turbo_stream" do
    sign_in @user

    post user_follow_path(@target.username), as: :turbo_stream
    assert_response :success
  end

  test "destroy responds to turbo_stream" do
    sign_in @user
    @user.follow(@target)

    delete user_follow_path(@target.username), as: :turbo_stream
    assert_response :success
  end
end
