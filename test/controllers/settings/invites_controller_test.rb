require "test_helper"

module Settings
  class InvitesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:alice)
      # Make user eligible for invite codes
      @user.update_columns(created_at: 10.days.ago)
    end

    test "index requires authentication" do
      get settings_invites_path
      assert_redirected_to new_user_session_path
    end

    test "index shows invite codes page" do
      sign_in @user
      get settings_invites_path
      assert_response :success
      assert_select "h1", /INVITE_CODES/
    end

    test "index shows eligibility status for eligible user" do
      sign_in @user
      get settings_invites_path
      assert_response :success
      assert_select ".text-acid-lime", /ELIGIBLE_TO_GENERATE/
    end

    test "index shows not eligible status for new user" do
      new_user = User.create!(
        email: "newuser@example.com",
        username: "newuser",
        password: "password123"
      )
      sign_in new_user
      get settings_invites_path
      assert_response :success
      assert_select ".text-acid-pink", /NOT_YET_ELIGIBLE/
    end

    test "index shows days until eligibility for new user" do
      new_user = User.create!(
        email: "newuser2@example.com",
        username: "newuser2",
        password: "password123"
      )
      sign_in new_user
      get settings_invites_path
      assert_response :success
      assert_match(/day\(s\) remaining/, response.body)
    end

    test "create requires authentication" do
      post settings_invites_path
      assert_redirected_to new_user_session_path
    end

    test "create generates invite codes for eligible user" do
      # Create a fresh eligible user with no codes
      fresh_user = User.create!(
        email: "freshcodes@example.com",
        username: "freshcodes",
        password: "password123"
      )
      fresh_user.update_columns(created_at: 10.days.ago)
      sign_in fresh_user

      assert_difference "fresh_user.invites_sent.count", User::INVITE_CODES_LIMIT do
        post settings_invites_path
      end

      assert_redirected_to settings_invites_path
      assert_match /Generated/, flash[:notice]
    end

    test "create does not generate codes for ineligible user" do
      new_user = User.create!(
        email: "ineligible@example.com",
        username: "ineligible",
        password: "password123"
      )
      sign_in new_user

      assert_no_difference "Invite.count" do
        post settings_invites_path
      end

      assert_redirected_to settings_invites_path
      assert_match /need to be a member/, flash[:alert]
    end

    test "create does not exceed invite limit" do
      sign_in @user

      # Generate max codes
      @user.generate_invite_codes!
      assert_equal User::INVITE_CODES_LIMIT, @user.invites_sent.available.count

      # Try to generate more
      assert_no_difference "Invite.count" do
        post settings_invites_path
      end

      assert_redirected_to settings_invites_path
      assert_match /maximum/, flash[:notice]
    end

    test "index displays existing invite codes" do
      sign_in @user
      @user.generate_invite_codes!

      get settings_invites_path
      assert_response :success

      @user.invite_codes.each do |code|
        assert_match code.code, response.body
      end
    end

    test "index shows used codes with invitee info" do
      sign_in @user
      @user.generate_invite_codes!

      # Mark one as used
      code = @user.invites_sent.first
      code.update!(used_at: Time.current, invitee: users(:charlie))

      get settings_invites_path
      assert_response :success
      assert_match /USED/, response.body
      assert_match /charlie/, response.body
    end

    test "index shows expiry information" do
      sign_in @user
      @user.generate_invite_codes!

      get settings_invites_path
      assert_response :success
      assert_match /expires in/, response.body
    end
  end
end
