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
  end
end
