require "test_helper"

module Api
  module V1
    class ThemesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @theme = themes(:build_in_public)
        @user = users(:alice)
        @api_key = @user.api_keys.create!(name: "Test Key")
      end

      # Index - public endpoint
      test "index does not require api key" do
        get api_v1_themes_path, as: :json
        assert_response :success
      end

      test "index returns all themes" do
        get api_v1_themes_path, as: :json

        assert_response :success
        data = response.parsed_body["data"]
        assert data.is_a?(Array)
        assert data.length >= 1

        theme_data = data.find { |t| t["id"] == @theme.id }
        assert_not_nil theme_data
        assert_equal @theme.name, theme_data["name"]
        assert_equal @theme.slug, theme_data["slug"]
      end

      test "index with api key also works" do
        get api_v1_themes_path,
            headers: { "Authorization" => "Bearer #{@api_key.raw_key}" },
            as: :json

        assert_response :success
      end

      # Show - public endpoint
      test "show does not require api key" do
        get api_v1_theme_path(@theme.slug), as: :json
        assert_response :success
      end

      test "show returns theme by slug" do
        get api_v1_theme_path(@theme.slug), as: :json

        assert_response :success
        data = response.parsed_body["data"]
        assert_equal @theme.id, data["id"]
        assert_equal @theme.name, data["name"]
        assert_equal @theme.slug, data["slug"]
        assert_equal @theme.description, data["description"]
        assert_equal @theme.color, data["color"]
      end

      test "show with invalid slug returns not found" do
        get api_v1_theme_path("nonexistent-theme"), as: :json
        assert_response :not_found
      end
    end
  end
end
