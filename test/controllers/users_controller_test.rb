require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "show displays user profile" do
    get user_path(@user.username)
    assert_response :success
  end

  test "show displays user posts" do
    get user_path(@user.username)
    assert_response :success
  end

  test "show with non-existent user returns 404" do
    get user_path(username: "nonexistent")
    assert_response :not_found
  end

  test "show supports pagination" do
    get user_path(@user.username, page: 1)
    assert_response :success
  end

  test "show uses username as param" do
    get user_path(@user.username)
    assert_response :success
  end
end
