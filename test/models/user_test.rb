require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    assert user.valid?
  end

  test "requires email" do
    user = User.new(username: "testuser", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    user = User.new(
      email: users(:alice).email,
      username: "newuser",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires username" do
    user = User.new(email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "requires unique username case insensitive" do
    user = User.new(
      email: "unique@example.com",
      username: users(:alice).username.upcase,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "username format allows lowercase letters numbers and underscores" do
    user = User.new(email: "test@example.com", password: "password123")

    user.username = "valid_user123"
    assert user.valid?

    user.username = "UPPERCASE"
    # normalizes to lowercase
    assert user.valid?
    assert_equal "uppercase", user.username

    user.username = "invalid-user"
    assert_not user.valid?

    user.username = "invalid.user"
    assert_not user.valid?
  end

  test "username length between 3 and 20" do
    user = User.new(email: "test@example.com", password: "password123")

    user.username = "ab"
    assert_not user.valid?

    user.username = "abc"
    assert user.valid?

    user.username = "a" * 20
    assert user.valid?

    user.username = "a" * 21
    assert_not user.valid?
  end

  test "reserved usernames are not allowed" do
    user = User.new(
      email: "test@example.com",
      username: "admin",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "is reserved"
  end

  test "to_param returns username" do
    assert_equal "alice", users(:alice).to_param
  end

  test "follow a user" do
    alice = users(:alice)
    charlie = users(:charlie)

    # alice doesn't follow charlie yet
    assert_not alice.following?(charlie)

    alice.follow(charlie)
    assert alice.following?(charlie)
  end

  test "cannot follow self" do
    alice = users(:alice)
    alice.follow(alice)
    assert_not alice.following?(alice)
  end

  test "cannot follow same user twice" do
    alice = users(:alice)
    bob = users(:bob)

    # Already following from fixtures
    assert alice.following?(bob)

    count_before = alice.following.count
    alice.follow(bob)
    assert_equal count_before, alice.following.count
  end

  test "unfollow a user" do
    alice = users(:alice)
    bob = users(:bob)

    assert alice.following?(bob)
    alice.unfollow(bob)
    assert_not alice.following?(bob)
  end

  test "timeline includes own posts and followed users posts" do
    alice = users(:alice)
    bob = users(:bob)

    # Alice follows bob (from fixtures)
    assert alice.following?(bob)

    timeline = alice.timeline
    # Should include alice's own posts
    assert timeline.where(user: alice).exists?
    # Should include bob's posts (alice follows bob)
    assert timeline.where(user: bob).exists?
  end

  test "normalizes email to lowercase" do
    user = User.new(
      email: "Test@EXAMPLE.com",
      username: "normalizetest",
      password: "password123"
    )
    assert_equal "test@example.com", user.email
  end
end
