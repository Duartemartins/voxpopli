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

  test "create with used invite code fails" do
    # Use the invite first
    @invite.use!(users(:bob))

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "latecomer",
          email: "late@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end
  end

  test "create with expired invite code fails" do
    expired_invite = Invite.create!(
      code: "EXPIREDCODE",
      inviter: users(:alice),
      expires_at: 1.day.ago
    )

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "expireduser",
          email: "expired@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: expired_invite.code
        }
      }
    end
  end

  test "create with case sensitive invite code requires exact match" do
    # Invite codes are case-sensitive - lowercase should fail
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "caseuser",
          email: "case@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code.downcase
        }
      }
    end
  end

  test "create with exact invite code works" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "exactuser",
          email: "exact@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end
  end

  test "create links invitee to inviter" do
    post user_registration_path, params: {
      user: {
        username: "linkeduser",
        email: "linked@example.com",
        password: "password123",
        password_confirmation: "password123",
        invite_code: @invite.code
      }
    }

    new_user = User.find_by(username: "linkeduser")
    @invite.reload

    assert_equal users(:alice), @invite.inviter
    assert_equal new_user, @invite.invitee
  end

  test "new with used invite code redirects" do
    @invite.use!(users(:bob))

    get new_user_registration_path(invite_code: @invite.code)
    assert_redirected_to root_path
    assert_equal "Valid invite code required to register", flash[:alert]
  end

  test "new with expired invite code redirects" do
    expired_invite = Invite.create!(
      code: "EXPIREDVIEW",
      inviter: users(:alice),
      expires_at: 1.day.ago
    )

    get new_user_registration_path(invite_code: expired_invite.code)
    assert_redirected_to root_path
    assert_equal "Valid invite code required to register", flash[:alert]
  end

  test "new displays invite code in hidden field" do
    get new_user_registration_path(invite_code: @invite.code)
    assert_response :success
    assert_select "input[name='user[invite_code]'][value='#{@invite.code}']"
  end

  # Destroy action tests
  test "destroy requires authentication" do
    delete user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "destroy deletes current user account" do
    user = User.create!(
      username: "tobedeleted",
      email: "delete@example.com",
      password: "password123"
    )
    sign_in user

    assert_difference "User.count", -1 do
      delete user_registration_path
    end

    assert_redirected_to root_path
  end

  test "destroy signs out user after deletion" do
    user = User.create!(
      username: "signoutuser",
      email: "signout@example.com",
      password: "password123"
    )
    sign_in user
    delete user_registration_path

    # Should not be authenticated after deletion
    get settings_account_path
    assert_redirected_to new_user_session_path
  end

  # Create with invalid user data (user not persisted)
  test "create with invalid user data does not use invite" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "x", # too short
          email: "invalid",
          password: "123",
          password_confirmation: "456",
          invite_code: @invite.code
        }
      }
    end

    @invite.reload
    assert_nil @invite.used_at
    assert @invite.available?
  end

  test "create with duplicate email does not use invite" do
    existing_user = users(:alice)

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "newusername",
          email: existing_user.email,
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end

    @invite.reload
    assert_nil @invite.used_at
  end

  test "create with duplicate username does not use invite" do
    existing_user = users(:alice)

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: existing_user.username,
          email: "unique@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end

    @invite.reload
    assert_nil @invite.used_at
  end

  test "create with password mismatch does not use invite" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "mismatchuser",
          email: "mismatch@example.com",
          password: "password123",
          password_confirmation: "differentpassword",
          invite_code: @invite.code
        }
      }
    end

    @invite.reload
    assert_nil @invite.used_at
  end

  test "validate_invite_code checks params invite_code first" do
    # When invite_code is in params (GET request style)
    get new_user_registration_path, params: { invite_code: @invite.code }
    assert_response :success
  end

  test "validate_invite_code falls back to user invite_code" do
    # This is tested via POST where invite_code is nested in user params
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "fallbackuser",
          email: "fallback@example.com",
          password: "password123",
          password_confirmation: "password123",
          invite_code: @invite.code
        }
      }
    end
  end

  test "destroy with sign_out_all_scopes true signs out completely" do
    # This tests the Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name) branch
    user = User.create!(
      username: "allscopesuser",
      email: "allscopes@example.com",
      password: "password123"
    )
    sign_in user

    # Store original value
    original_value = Devise.sign_out_all_scopes

    begin
      Devise.sign_out_all_scopes = true
      delete user_registration_path
      assert_redirected_to root_path
    ensure
      Devise.sign_out_all_scopes = original_value
    end
  end

  test "destroy with sign_out_all_scopes false signs out resource only" do
    user = User.create!(
      username: "onescopeuser",
      email: "onescope@example.com",
      password: "password123"
    )
    sign_in user

    original_value = Devise.sign_out_all_scopes

    begin
      Devise.sign_out_all_scopes = false
      delete user_registration_path
      assert_redirected_to root_path
    ensure
      Devise.sign_out_all_scopes = original_value
    end
  end

  test "validate_invite_code with nil code redirects" do
    get new_user_registration_path, params: { invite_code: nil }
    assert_redirected_to root_path
    assert_equal "Valid invite code required to register", flash[:alert]
  end

  test "validate_invite_code with empty code redirects" do
    get new_user_registration_path, params: { invite_code: "" }
    assert_redirected_to root_path
    assert_equal "Valid invite code required to register", flash[:alert]
  end
end
