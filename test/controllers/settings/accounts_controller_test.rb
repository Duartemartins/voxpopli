require "test_helper"

module Settings
  class AccountsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:alice)
    end

    test "show requires authentication" do
      get settings_account_path
      assert_redirected_to new_user_session_path
    end

    test "show displays account settings" do
      sign_in @user
      get settings_account_path
      assert_response :success
    end

    test "destroy requires authentication" do
      delete settings_account_path
      assert_redirected_to new_user_session_path
    end

    test "destroy deletes account" do
      sign_in @user

      assert_difference "User.count", -1 do
        delete settings_account_path
      end

      assert_redirected_to root_path
    end

    test "destroy signs out user" do
      sign_in @user
      delete settings_account_path

      # Should not be able to access authenticated routes after deletion
      get settings_account_path
      assert_redirected_to new_user_session_path
    end

    # Invite codes display tests
    test "show displays invite codes section" do
      sign_in @user
      get settings_account_path
      assert_response :success
      assert_select "h2", text: "Invite Codes"
    end

    test "show creates 5 invite codes for user without any" do
      # Create a fresh user with no invite codes
      fresh_user = User.create!(
        email: "fresh@example.com",
        username: "freshuser",
        password: "password123"
      )
      assert_equal 0, fresh_user.invites_sent.count

      sign_in fresh_user
      get settings_account_path

      assert_response :success
      fresh_user.reload
      assert_equal 5, fresh_user.invites_sent.count
    end

    test "show displays all 5 invite codes" do
      sign_in @user
      get settings_account_path

      assert_response :success
      # Should display 5 invite code entries
      assert_select ".bg-gray-50.rounded-lg", count: 5
    end

    test "show displays available badge for unused codes" do
      sign_in @user
      get settings_account_path

      assert_response :success
      assert_select "span", text: "Available"
    end

    test "show displays used badge for used codes" do
      # Create user with some used invite codes
      inviter = User.create!(
        email: "inviter2@example.com",
        username: "inviter2",
        password: "password123"
      )
      inviter.ensure_invite_codes!

      # Use one of the codes
      invitee = User.create!(
        email: "invitee2@example.com",
        username: "invitee2",
        password: "password123"
      )
      inviter.invite_codes.first.use!(invitee)

      sign_in inviter
      get settings_account_path

      assert_response :success
      assert_select "span", text: "Used"
      assert_select "span", text: "Available", count: 4
    end

    test "show displays who used the invite code" do
      inviter = User.create!(
        email: "inviter3@example.com",
        username: "inviter3",
        password: "password123"
      )
      inviter.ensure_invite_codes!

      invitee = User.create!(
        email: "invitee3@example.com",
        username: "invitee3",
        password: "password123"
      )
      inviter.invite_codes.first.use!(invitee)

      sign_in inviter
      get settings_account_path

      assert_response :success
      assert_match "invitee3", response.body
    end

    test "show displays copy button only for available codes" do
      inviter = User.create!(
        email: "inviter4@example.com",
        username: "inviter4",
        password: "password123"
      )
      inviter.ensure_invite_codes!

      invitee = User.create!(
        email: "invitee4@example.com",
        username: "invitee4",
        password: "password123"
      )
      inviter.invite_codes.first.use!(invitee)

      sign_in inviter
      get settings_account_path

      assert_response :success
      # Should have 4 Copy buttons (one for each available code)
      assert_select "button", text: "Copy", count: 4
    end

    test "show displays invite code values" do
      sign_in @user
      get settings_account_path

      @user.invite_codes.each do |invite|
        assert_match invite.code, response.body
      end
    end
  end
end
