require "test_helper"

module Api
  module V1
    class MeControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:alice)
        @api_key = @user.api_keys.create!(name: "Test Key")
      end

      test "show without api key returns unauthorized" do
        get api_v1_me_path
        assert_response :unauthorized
        assert_equal "Invalid or missing API key", response.parsed_body["error"]
      end

      test "show with invalid api key returns unauthorized" do
        get api_v1_me_path, headers: { "Authorization" => "Bearer invalid_key" }
        assert_response :unauthorized
      end

      test "show returns current user profile" do
        get api_v1_me_path, headers: auth_headers(@api_key)

        assert_response :success
        data = response.parsed_body["data"]
        assert_equal @user.id, data["id"]
        assert_equal @user.username, data["username"]
        assert_equal @user.email, data["email"]
      end

      test "show returns correct fields" do
        get api_v1_me_path, headers: auth_headers(@api_key)

        assert_response :success
        data = response.parsed_body["data"]
        assert data.key?("posts_count")
        assert data.key?("followers_count")
        assert data.key?("following_count")
      end

      private

      def auth_headers(api_key)
        { "Authorization" => "Bearer #{api_key.raw_key}" }
      end
    end
  end
end
