require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "avatar_for with avatar_url shows image" do
    user = users(:alice)
    user.avatar_url = "https://example.com/avatar.jpg"

    html = avatar_for(user)
    assert_match(/img/, html)
    assert_match(/src="https:\/\/example.com\/avatar.jpg"/, html)
    assert_match(/rounded-full/, html)
  end

  test "avatar_for without avatar_url shows initial" do
    user = users(:alice)
    user.avatar_url = nil

    html = avatar_for(user)
    assert_match(/A/, html)  # First letter of 'alice'
    assert_match(/rounded-full/, html)
    assert_match(/bg-\[#003399\]/, html)
  end

  test "avatar_for small size" do
    user = users(:alice)
    user.avatar_url = nil

    html = avatar_for(user, size: :small)
    assert_match(/w-8 h-8/, html)
  end

  test "avatar_for medium size" do
    user = users(:alice)
    user.avatar_url = nil

    html = avatar_for(user, size: :medium)
    assert_match(/w-12 h-12/, html)
  end

  test "avatar_for large size" do
    user = users(:alice)
    user.avatar_url = nil

    html = avatar_for(user, size: :large)
    assert_match(/w-20 h-20/, html)
  end

  test "avatar_for uses display_name in alt text if present" do
    user = users(:alice)
    user.display_name = "Alice Builder"
    user.avatar_url = "https://example.com/avatar.jpg"

    html = avatar_for(user)
    assert_match(/alt="Alice Builder/, html)
  end
end
