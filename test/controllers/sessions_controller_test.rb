require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  # Render tests for _links partial coverage
  test "new renders sign in form" do
    get new_user_session_path
    assert_response :success
    assert_select "form"
  end

  test "new does not show login link on sessions page" do
    get new_user_session_path
    assert_response :success
    # _links partial should not show login link on sessions page (already on login)
    assert_select "a", text: "EXISTING_OPERATIVE? // LOGIN", count: 0
  end

  test "new shows forgot password link" do
    get new_user_session_path
    assert_response :success
    # recoverable is enabled, so forgot password link should appear
    assert_select "a[href='#{new_user_password_path}']", text: "LOST_CREDENTIALS? // RECOVER"
  end

  test "create with valid credentials signs in user" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    assert_redirected_to root_path
    follow_redirect!
    # Check that user is signed in (can access settings)
    get settings_account_path
    assert_response :success
  end

  test "create with invalid credentials shows error" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }
    assert_response :unprocessable_entity
  end

  test "destroy signs out user" do
    sign_in @user
    delete destroy_user_session_path
    assert_redirected_to root_path

    # Verify signed out
    get settings_account_path
    assert_redirected_to new_user_session_path
  end

  # Layout coverage tests
  test "signed in user sees nav with profile and settings links" do
    sign_in @user
    get root_path
    assert_response :success
    # Check for profile and settings links in the nav
    assert_select "a[href='#{user_path(@user)}']"
    assert_select "a[href='#{settings_account_path}']"
  end

  test "signed out user sees login and join links" do
    get root_path
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']", text: "[ LOGIN ]"
    assert_select "a[href='#{join_path}']", text: "[ REGISTER ]"
  end

  test "notice flash message is displayed" do
    sign_in @user
    # Force a notice message by creating a post
    post posts_path, params: {
      post: { body: "Test post for notice" }
    }
    follow_redirect!
    # Check for flash notice in the Cyber Brutalist style
    assert_select ".border-acid-lime", /SYSTEM_NOTICE/
  end

  test "alert flash message is displayed" do
    # Try to access protected page without signing in
    get settings_account_path
    follow_redirect!
    # Check for flash alert in the Cyber Brutalist style
    assert_select ".border-acid-pink", /SYSTEM_ALERT/
  end
end
