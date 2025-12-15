require "test_helper"

class DirectoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @unconfirmed = users(:unconfirmed)
  end

  # Index tests
  test "should get index" do
    get directory_url
    assert_response :success
    assert_select "h1", /BUILDER_DIRECTORY/
  end

  test "index shows only confirmed users" do
    get directory_url
    assert_response :success
    assert_match @alice.username, response.body
    assert_match @bob.username, response.body
    assert_no_match(/unconfirmed/, response.body)
  end

  test "index filters by skill" do
    get directory_url, params: { skill: "Rails" }
    assert_response :success
    assert_match @alice.username, response.body
    assert_no_match(/bob/, response.body)
  end

  test "index filters by looking_for" do
    get directory_url, params: { looking_for: "cofounders" }
    assert_response :success
    assert_match @alice.username, response.body
    assert_no_match(/bob/, response.body)
  end

  test "index searches by username" do
    get directory_url, params: { q: "alice" }
    assert_response :success
    assert_match @alice.username, response.body
    assert_no_match(/bob/, response.body)
  end

  test "index searches by tagline" do
    get directory_url, params: { q: "indie products" }
    assert_response :success
    assert_match @alice.username, response.body
  end

  test "index sorts by newest" do
    get directory_url, params: { sort: "newest" }
    assert_response :success
  end

  test "index sorts by active" do
    get directory_url, params: { sort: "active" }
    assert_response :success
  end

  test "index defaults to grid view" do
    get directory_url
    assert_response :success
    assert_select "div.grid"
  end

  test "index supports list view" do
    get directory_url, params: { view: "list" }
    assert_response :success
    assert_select "div.space-y-2"
  end

  test "index view toggle preserves other params" do
    get directory_url, params: { view: "list", q: "alice", skill: "Rails" }
    assert_response :success
    assert_match @alice.username, response.body
  end

  test "index responds to json" do
    get directory_url, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  # Show tests - now redirects to user profile
  test "should redirect show to user profile" do
    get directory_user_url(@alice.username)
    assert_redirected_to user_path(@alice.username)
    assert_response :moved_permanently
  end

  test "show redirects with 301 status" do
    get directory_user_url(@alice.username)
    assert_response 301
  end

  test "show returns 404 for non-existent user" do
    get directory_user_url("nonexistent")
    assert_response :not_found
  end

  # Sitemap tests
  test "should get sitemap" do
    get directory_sitemap_url(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "sitemap includes directory index" do
    get directory_sitemap_url(format: :xml)
    assert_match directory_url, response.body
  end

  test "sitemap includes confirmed users" do
    get directory_sitemap_url(format: :xml)
    assert_match user_url(@alice.username), response.body
    assert_match user_url(@bob.username), response.body
  end

  test "sitemap excludes unconfirmed users" do
    get directory_sitemap_url(format: :xml)
    assert_no_match(/unconfirmed/, response.body)
  end

  # Authenticated user tests - now tests redirect
  test "directory show redirects logged in user to user profile" do
    sign_in @bob
    get directory_user_url(@alice.username)
    assert_redirected_to user_path(@alice.username)
  end

  test "directory show redirects user to own profile" do
    sign_in @alice
    get directory_user_url(@alice.username)
    assert_redirected_to user_path(@alice.username)
  end
end
