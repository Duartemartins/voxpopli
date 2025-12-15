require "test_helper"

class TimelineControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:alice)
    @theme = themes(:build_in_public)
  end

  test "index without authentication shows all original posts" do
    get timeline_path
    assert_response :success
    assert_select ".post", count: Post.original.count
  end

  test "index with authentication shows timeline" do
    sign_in @user
    get timeline_path
    assert_response :success
    # Alice follows Bob, so she should see Bob's posts
    # She should NOT see posts from someone she doesn't follow (unless global fallback was active, but she follows someone)
  end

  test "index shows global feed for user following no one" do
    # Create a user who follows no one
    lonely_user = User.create!(
      email: "lonely@example.com",
      username: "lonely",
      password: "password123"
    )
    
    sign_in lonely_user
    get timeline_path
    assert_response :success
    
    # Should see global posts (e.g. from Alice or Bob)
    assert_select ".post", count: Post.original.count
  end


  test "index with new view" do
    get timeline_path(view: "new")
    assert_response :success
  end

  test "index with voted view" do
    get timeline_path(view: "voted")
    assert_response :success
  end

  test "index ignores invalid view parameter" do
    get timeline_path(view: "invalid")
    assert_response :success
  end

  test "index filters by theme" do
    get timeline_path(theme: @theme.slug)
    assert_response :success
  end

  test "index with non-existent theme" do
    get timeline_path(theme: "non-existent")
    assert_response :success
  end

  test "index supports pagination" do
    get timeline_path(page: 1)
    assert_response :success
  end

  test "index with explicit feed param" do
    sign_in @user
    
    # Explicitly ask for global feed
    get timeline_path(feed: "global")
    assert_response :success
    
    # Explicitly ask for following feed
    get timeline_path(feed: "following")
    assert_response :success
  end

  test "index displays theme links" do
    get timeline_path
    assert_response :success
    assert_select "a[href*='theme=#{@theme.slug}']", text: "// #{@theme.name.upcase}"
  end
end
