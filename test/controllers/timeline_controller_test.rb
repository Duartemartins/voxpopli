require "test_helper"

class TimelineControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @theme = themes(:build_in_public)
  end

  test "index without authentication shows all original posts" do
    get timeline_path
    assert_response :success
  end

  test "index with authentication shows timeline" do
    sign_in @user
    get timeline_path
    assert_response :success
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
end
