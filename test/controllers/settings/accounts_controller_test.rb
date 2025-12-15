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
      # Make user eligible
      @user.update_columns(created_at: 10.days.ago)
      @user.ensure_invite_codes!

      get settings_account_path
      assert_response :success
      assert_match "INVITE_CODES", response.body
    end

    test "show displays invite codes for eligible user" do
      # Create an eligible user with invite codes
      eligible_user = User.create!(
        email: "eligible@example.com",
        username: "eligibleuser",
        password: "password123"
      )
      eligible_user.update_columns(created_at: 10.days.ago)
      eligible_user.ensure_invite_codes!

      assert_equal User::INVITE_CODES_LIMIT, eligible_user.invites_sent.count

      sign_in eligible_user
      get settings_account_path

      assert_response :success
      # Should display invite codes
      eligible_user.invite_codes.each do |invite|
        assert_match invite.code, response.body
      end
    end

    test "show displays used status for used codes" do
      # Create user with some used invite codes
      inviter = User.create!(
        email: "inviter2@example.com",
        username: "inviter2",
        password: "password123"
      )
      inviter.update_columns(created_at: 10.days.ago)
      inviter.ensure_invite_codes!

      # Use one of the codes
      invitee = User.create!(
        email: "invitee2@example.com",
        username: "invitee2",
        password: "password123"
      )
      inviter.invites_sent.available.first.use!(invitee)

      sign_in inviter
      get settings_account_path

      assert_response :success
      # Should show the used code as depleted
      assert_match "DEPLETED", response.body
      assert_match "ACTIVE", response.body
    end

    test "show displays who used the invite code" do
      inviter = User.create!(
        email: "inviter3@example.com",
        username: "inviter3",
        password: "password123"
      )
      inviter.update_columns(created_at: 10.days.ago)
      inviter.ensure_invite_codes!

      invitee = User.create!(
        email: "invitee3@example.com",
        username: "invitee3",
        password: "password123"
      )
      inviter.invites_sent.available.first.use!(invitee)

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
      inviter.update_columns(created_at: 10.days.ago)
      inviter.ensure_invite_codes!

      invitee = User.create!(
        email: "invitee4@example.com",
        username: "invitee4",
        password: "password123"
      )
      inviter.invites_sent.available.first.use!(invitee)

      sign_in inviter
      get settings_account_path

      assert_response :success
      # The system replenishes codes, so after using one, a new one is created
      # Total all codes = LIMIT + 1 used = 4 total (1 used, 3 available)
      # Should have COPY buttons for all available codes (3)
      assert_select "button", text: "COPY", count: User::INVITE_CODES_LIMIT
    end

    test "show displays invite code values" do
      sign_in @user
      @user.update_columns(created_at: 10.days.ago)
      @user.ensure_invite_codes!

      get settings_account_path

      @user.invite_codes.each do |invite|
        assert_match invite.code, response.body
      end
    end
  end
end
