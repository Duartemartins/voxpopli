require "test_helper"

class FollowTest < ActiveSupport::TestCase
  test "valid follow" do
    follow = Follow.new(
      follower: users(:charlie),
      followed: users(:bob)
    )
    assert follow.valid?
  end

  test "requires unique follower-followed pair" do
    existing = follows(:alice_follows_bob)

    duplicate = Follow.new(
      follower: existing.follower,
      followed: existing.followed
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:follower_id], "has already been taken"
  end

  test "cannot follow self" do
    follow = Follow.new(
      follower: users(:alice),
      followed: users(:alice)
    )
    assert_not follow.valid?
    assert_includes follow.errors[:base], "You cannot follow yourself"
  end

  test "creates notification on follow" do
    assert_difference "Notification.count", 1 do
      Follow.create!(
        follower: users(:charlie),
        followed: users(:bob)
      )
    end
  end

  test "updates counter cache on create" do
    charlie = users(:charlie)
    bob = users(:bob)

    initial_following = charlie.following_count
    initial_followers = bob.followers_count

    Follow.create!(follower: charlie, followed: bob)

    charlie.reload
    bob.reload

    assert_equal initial_following + 1, charlie.following_count
    assert_equal initial_followers + 1, bob.followers_count
  end
end
