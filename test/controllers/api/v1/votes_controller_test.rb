require "test_helper"

module Api
  module V1
    class VotesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:alice)
        @api_key = @user.api_keys.create!(name: "Test Key")
        # Use a post which alice hasn't voted on yet
        @unvoted_post = posts(:post_without_theme)
        # Use bob's post which alice has already upvoted (from fixtures)
        @voted_post = posts(:bob_post)
      end

      # Create vote
      test "create vote without api key returns unauthorized" do
        post api_v1_post_vote_path(@unvoted_post), as: :json
        assert_response :unauthorized
      end

      test "create upvote on unvoted post" do
        assert_difference "@unvoted_post.votes.count", 1 do
          post api_v1_post_vote_path(@unvoted_post),
               params: { value: 1 },
               headers: auth_headers(@api_key),
               as: :json
        end

        assert_response :created
        data = response.parsed_body["data"]
        assert_equal @unvoted_post.id, data["post_id"]
        assert_equal 1, data["voted"]
      end

      test "create same vote again toggles it off" do
        # Alice already upvoted bob's post, voting again removes it
        assert_difference "@voted_post.votes.count", -1 do
          post api_v1_post_vote_path(@voted_post),
               params: { value: 1 },
               headers: auth_headers(@api_key),
               as: :json
        end

        assert_response :success
        data = response.parsed_body["data"]
        assert_nil data["voted"]
      end

      test "create opposite vote changes existing vote" do
        # Alice upvoted bob's post, downvote should change it
        assert_no_difference "@voted_post.votes.count" do
          post api_v1_post_vote_path(@voted_post),
               params: { value: -1 },
               headers: auth_headers(@api_key),
               as: :json
        end

        assert_response :success
        assert_equal(-1, response.parsed_body["data"]["voted"])
      end

      test "create vote defaults to upvote for invalid value" do
        post api_v1_post_vote_path(@unvoted_post),
             params: { value: 999 },
             headers: auth_headers(@api_key),
             as: :json

        assert_response :created
        assert_equal 1, response.parsed_body["data"]["voted"]
      end

      test "create vote updates post score" do
        original_score = @unvoted_post.score

        post api_v1_post_vote_path(@unvoted_post),
             params: { value: 1 },
             headers: auth_headers(@api_key),
             as: :json

        assert_response :created
        assert_equal original_score + 1, response.parsed_body["data"]["score"]
      end

      # Destroy vote
      test "destroy vote without api key returns unauthorized" do
        delete api_v1_post_vote_path(@voted_post), as: :json
        assert_response :unauthorized
      end

      test "destroy removes existing vote" do
        assert_difference "@voted_post.votes.count", -1 do
          delete api_v1_post_vote_path(@voted_post),
                 headers: auth_headers(@api_key),
                 as: :json
        end

        assert_response :success
        data = response.parsed_body["data"]
        assert_nil data["voted"]
      end

      test "destroy returns not found when no vote exists" do
        delete api_v1_post_vote_path(@unvoted_post),
               headers: auth_headers(@api_key),
               as: :json

        assert_response :not_found
      end

      test "vote on nonexistent post returns not found" do
        post api_v1_post_vote_path("nonexistent"),
             params: { value: 1 },
             headers: auth_headers(@api_key),
             as: :json

        assert_response :not_found
      end

      private

      def auth_headers(api_key)
        { "Authorization" => "Bearer #{api_key.raw_key}" }
      end
    end
  end
end
