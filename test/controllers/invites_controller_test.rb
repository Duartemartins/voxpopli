require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_invite = invites(:available_invite)
    @used_invite = invites(:used_invite)
    @expired_invite = invites(:expired_invite)
  end

  test "new displays invite form" do
    get join_path
    assert_response :success
  end

  test "verify with valid code redirects to registration" do
    post verify_invite_path, params: { code: @valid_invite.code }
    assert_redirected_to new_user_registration_path(invite_code: @valid_invite.code)
  end

  test "verify with lowercase code works" do
    post verify_invite_path, params: { code: @valid_invite.code.downcase }
    assert_redirected_to new_user_registration_path(invite_code: @valid_invite.code.upcase)
  end

  test "verify with used code shows error" do
    post verify_invite_path, params: { code: @used_invite.code }
    assert_response :unprocessable_entity
    assert_select "body"  # Re-renders new template
  end

  test "verify with expired code shows error" do
    post verify_invite_path, params: { code: @expired_invite.code }
    assert_response :unprocessable_entity
  end

  test "verify with invalid code shows error" do
    post verify_invite_path, params: { code: "INVALID12345" }
    assert_response :unprocessable_entity
  end

  test "verify with blank code shows error" do
    post verify_invite_path, params: { code: "" }
    assert_response :unprocessable_entity
  end

  test "verify strips whitespace from code" do
    post verify_invite_path, params: { code: "  #{@valid_invite.code}  " }
    assert_redirected_to new_user_registration_path(invite_code: @valid_invite.code)
  end
end
