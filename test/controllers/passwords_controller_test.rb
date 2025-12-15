require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  # Render tests for _links partial coverage
  test "new renders forgot password form" do
    get new_user_password_path
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[email]']"
  end

  test "new shows sign in link on passwords page" do
    get new_user_password_path
    assert_response :success
    # Should show login link in Cyber Brutalist style
    assert_select "a[href='#{new_user_session_path}']", text: "EXISTING_OPERATIVE? // LOGIN"
  end

  test "new does not show forgot password link on passwords page" do
    get new_user_password_path
    assert_response :success
    # Should not show forgot password link on the passwords page itself
    assert_select "a", text: "LOST_CREDENTIALS? // RECOVER", count: 0
  end

  test "create with valid email sends reset instructions" do
    assert_emails 1 do
      post user_password_path, params: {
        user: { email: @user.email }
      }
    end
    assert_redirected_to new_user_session_path
  end

  test "create with invalid email still redirects for security" do
    # Devise typically doesn't reveal if email exists
    post user_password_path, params: {
      user: { email: "nonexistent@example.com" }
    }
    # Should redirect to sign in regardless
    assert_redirected_to new_user_session_path
  end

  test "edit with valid reset token shows form" do
    token = @user.send_reset_password_instructions
    get edit_user_password_path(reset_password_token: token)
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "edit shows sign in link" do
    token = @user.send_reset_password_instructions
    get edit_user_password_path(reset_password_token: token)
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']", text: "EXISTING_OPERATIVE? // LOGIN"
  end

  test "update with valid token and password resets password" do
    token = @user.send_reset_password_instructions
    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_redirected_to root_path

    # Verify new password works
    sign_out @user
    post user_session_path, params: {
      user: { email: @user.email, password: "newpassword123" }
    }
    assert_redirected_to root_path
  end

  test "update with invalid token shows error" do
    patch user_password_path, params: {
      user: {
        reset_password_token: "invalidtoken",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_response :unprocessable_entity
  end

  test "update with mismatched passwords shows error" do
    token = @user.send_reset_password_instructions
    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "differentpassword"
      }
    }
    assert_response :unprocessable_entity
  end
end
