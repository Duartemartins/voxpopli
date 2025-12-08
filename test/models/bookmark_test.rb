require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  test "valid bookmark" do
    bookmark = Bookmark.new(
      user: users(:charlie),
      post: posts(:alice_post)
    )
    assert bookmark.valid?
  end

  test "user can only bookmark a post once" do
    existing = bookmarks(:alice_bookmarks_bob_post)

    duplicate = Bookmark.new(
      user: existing.user,
      post: existing.post
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "user can bookmark multiple posts" do
    user = users(:charlie)

    bookmark1 = Bookmark.create!(user: user, post: posts(:alice_post))
    bookmark2 = Bookmark.create!(user: user, post: posts(:bob_post))

    assert bookmark1.persisted?
    assert bookmark2.persisted?
    assert_equal 2, user.bookmarks.count
  end
end
