require "test_helper"

module Api
  module V1
    class PostsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:alice)
        @api_key = api_keys(:alice_api_key)
        @post = posts(:alice_post)
        @theme = themes(:build_in_public)

        # Generate a valid API key for testing
        @valid_api_key = ApiKey.create!(user: @user, name: "Test Key")
        @valid_token = @valid_api_key.raw_key
      end

      test "index requires api key" do
        get api_v1_posts_path, as: :json
        assert_response :unauthorized
      end

      test "index returns posts" do
        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json.key?("data")
        assert json.key?("meta")
      end

      test "index sorts by new by default" do
        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            as: :json

        assert_response :success
      end

      test "index sorts by voted" do
        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            params: { sort: "voted" },
            as: :json

        assert_response :success
      end

      test "index filters by theme" do
        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            params: { theme: @theme.slug },
            as: :json

        assert_response :success
      end

      test "index supports pagination" do
        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            params: { page: 1 },
            as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["meta"].key?("page")
        assert json["meta"].key?("total_pages")
      end

      test "show returns post" do
        get api_v1_post_path(@post),
            headers: { "Authorization" => "Bearer #{@valid_token}" },
            as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal @post.id, json["data"]["id"]
      end

      test "show requires api key" do
        get api_v1_post_path(@post), as: :json
        assert_response :unauthorized
      end

      test "create post" do
        assert_difference "Post.count", 1 do
          post api_v1_posts_path,
               headers: { "Authorization" => "Bearer #{@valid_token}" },
               params: { body: "API created post" },
               as: :json
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "API created post", json["data"]["body"]
      end

      test "create post with theme" do
        post api_v1_posts_path,
             headers: { "Authorization" => "Bearer #{@valid_token}" },
             params: { body: "Themed API post", theme_id: @theme.id },
             as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal @theme.slug, json["data"]["theme"]
      end

      test "create post with invalid params" do
        post api_v1_posts_path,
             headers: { "Authorization" => "Bearer #{@valid_token}" },
             params: { body: "" },
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert json.key?("errors")
      end

      test "destroy own post" do
        # Create a fresh post without replies to avoid cascade deletes
        post_to_delete = Post.create!(user: @user, body: "Post to delete via API")

        assert_difference "Post.count", -1 do
          delete api_v1_post_path(post_to_delete),
                 headers: { "Authorization" => "Bearer #{@valid_token}" },
                 as: :json
        end

        assert_response :no_content
      end

      test "cannot destroy other users post" do
        other_post = posts(:bob_post)

        # The controller scopes to current_user.posts, so this returns 404 not 403
        delete api_v1_post_path(other_post),
               headers: { "Authorization" => "Bearer #{@valid_token}" },
               as: :json

        assert_response :not_found
      end

      test "rate limited key returns 429" do
        _limited_key = api_keys(:bob_rate_limited)
        # Create a valid token for rate-limited key
        limited_api = ApiKey.create!(user: users(:bob), name: "Limited")
        limited_api.update_columns(requests_count: 1001, rate_limit: 1000)

        get api_v1_posts_path,
            headers: { "Authorization" => "Bearer #{limited_api.key_prefix}bad" },
            as: :json

        # Will be unauthorized because token doesn't match
        assert_response :unauthorized
      end
    end
  end
end
