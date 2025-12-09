require "test_helper"

module Settings
  class ApiKeysControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:alice)
    end

    test "index requires authentication" do
      get settings_api_keys_path
      assert_redirected_to new_user_session_path
    end

    test "index shows api keys page" do
      sign_in @user
      get settings_api_keys_path
      assert_response :success
      assert_select "h1", "API Keys"
    end

    test "index lists user api keys" do
      sign_in @user
      @user.api_keys.create!(name: "Test Key")

      get settings_api_keys_path
      assert_response :success
      assert_select "li", /Test Key/
    end

    test "create requires authentication" do
      post settings_api_keys_path, params: { api_key: { name: "My Key" } }
      assert_redirected_to new_user_session_path
    end

    test "create generates new api key" do
      sign_in @user

      assert_difference "@user.api_keys.count", 1 do
        post settings_api_keys_path, params: { api_key: { name: "My App" } }
      end

      assert_redirected_to settings_api_keys_path
      assert flash[:api_key].present?
      assert flash[:api_key].start_with?("bb_live_")
    end

    test "create with blank name shows error" do
      sign_in @user

      assert_no_difference "ApiKey.count" do
        post settings_api_keys_path, params: { api_key: { name: "" } }
      end

      assert_response :unprocessable_entity
    end

    test "destroy requires authentication" do
      api_key = @user.api_keys.create!(name: "Test Key")
      delete settings_api_key_path(api_key)
      assert_redirected_to new_user_session_path
    end

    test "destroy revokes api key" do
      sign_in @user
      api_key = @user.api_keys.create!(name: "Test Key")

      assert_difference "@user.api_keys.count", -1 do
        delete settings_api_key_path(api_key)
      end

      assert_redirected_to settings_api_keys_path
    end

    test "cannot destroy other users api key" do
      sign_in users(:bob)
      api_key = @user.api_keys.create!(name: "Alice Key")

      # Controller scopes to current_user.api_keys, so it won't find alice's key
      assert_no_difference "ApiKey.count" do
        begin
          delete settings_api_key_path(api_key)
        rescue ActiveRecord::RecordNotFound
          # Expected behavior
        end
      end
    end
  end
end
