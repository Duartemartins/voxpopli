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

  test "new does not show sign in link on sessions page" do
    get new_user_session_path
    assert_response :success
    # _links partial should not show "Already have an account?" on sessions page
    assert_select "a", text: "Already have an account? Sign in", count: 0
  end

  test "new shows forgot password link" do
    get new_user_session_path
    assert_response :success
    # recoverable is enabled, so forgot password link should appear
    assert_select "a[href='#{new_user_password_path}']", text: "Forgot your password?"
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
    assert_select "a", text: @user.username
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
  test "signed in user sees nav with username and settings" do
    sign_in @user
    get root_path
    assert_response :success
    assert_select "a[href='#{user_path(@user)}']", text: @user.username
    assert_select "a[href='#{settings_account_path}']", text: "Settings"
    assert_select "button", text: "Sign out"
  end

  test "signed out user sees sign in and sign up links" do
    get root_path
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']", text: "Sign in"
    assert_select "a[href='#{join_path}']", text: "Sign up"
  end

  test "notice flash message is displayed" do
    sign_in @user
    get root_path
    # Force a notice message
    post posts_path, params: {
      post: { body: "Test post for notice" }
    }
    follow_redirect!
    assert_select ".bg-green-100"
  end

  test "alert flash message is displayed" do
    # Try to access protected page without signing in
    get settings_account_path
    follow_redirect!
    assert_select ".bg-red-100"
  end
end
