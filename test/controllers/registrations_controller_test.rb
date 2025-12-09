require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invite = Invite.create!(
      code: "TESTCODE123",
      inviter: users(:alice)
    )
  end

  test "new requires valid invite code" do
    get new_user_registration_path
    assert_redirected_to root_path
    assert_equal "Valid invite code required to register", flash[:alert]
  end

  test "new with invalid invite code redirects" do
    get new_user_registration_path(invite_code: "INVALID")
    assert_redirected_to root_path
  end

  test "new with valid invite code shows form" do
    get new_user_registration_path(invite_code: @invite.code)
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[username]']"
  end

  test "create requires valid invite code" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "newuser",
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: "INVALID"
        }
      }
    end
  end

  test "create with valid invite code creates user" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "newuser",
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end

    user = User.find_by(username: "newuser")
    assert_not_nil user
    assert_equal "new@example.com", user.email
  end

  test "create marks invite as used" do
    post user_registration_path, params: {
      user: {
        username: "newuser2",
        email: "new2@example.com",
        password: "password123",
        password_confirmation: "password123",
        invite_code: @invite.code
      }
    }

    @invite.reload
    assert_not_nil @invite.used_at
    user = User.find_by(username: "newuser2")
    assert_equal user.id, @invite.invitee_id
  end

  # Honeypot anti-bot tests
  test "create with empty honeypot field succeeds" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "realuser",
          email: "real@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code,
          website_url: ""
        }
      }
    end
  end

  test "create with filled honeypot field is rejected as bot" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "botuser",
          email: "bot@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code,
          website_url: "http://spam.com"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Registration failed", flash[:alert]
  end

  test "create without honeypot field succeeds" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "normaluser",
          email: "normal@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end
  end
end
