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

  test "can attach avatar" do
    user = users(:alice)
    assert_not user.avatar.attached?

    user.avatar.attach(io: File.open(Rails.root.join("test/fixtures/files/test_image.jpg")), filename: "test_image.jpg", content_type: "image/jpeg")
    assert user.avatar.attached?
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

  test "website must be a valid url" do
    user = users(:alice)

    user.website = "not-a-url"
    assert_not user.valid?
    assert_includes user.errors[:website], "must be a valid URL"

    user.website = "ftp://invalid.com"
    assert_not user.valid?

    user.website = "http://valid.com"
    assert user.valid?

    user.website = "https://valid.com"
    assert user.valid?

    user.website = ""
    assert user.valid?

    user.website = nil
    assert user.valid?
  end

  test "avatar_url must be a valid url" do
    user = users(:alice)

    user.avatar_url = "not-a-url"
    assert_not user.valid?
    assert_includes user.errors[:avatar_url], "must be a valid URL"

    user.avatar_url = "ftp://invalid.com/avatar.png"
    assert_not user.valid?

    user.avatar_url = "http://valid.com/avatar.png"
    assert user.valid?

    user.avatar_url = "https://valid.com/avatar.png"
    assert user.valid?

    user.avatar_url = ""
    assert user.valid?

    user.avatar_url = nil
    assert user.valid?
  end

  test "ensure_invite_codes! creates 5 invite codes for new user" do
    user = User.create!(
      email: "newinviteuser@example.com",
      username: "newinviteuser",
      password: "password123"
    )
    assert_equal 0, user.invites_sent.count

    codes = user.ensure_invite_codes!

    assert_equal 5, codes.count
    assert_equal 5, user.invites_sent.count
    codes.each do |invite|
      assert_not_nil invite.code
      assert invite.available?
      assert_equal user, invite.inviter
    end
  end

  test "ensure_invite_codes! does not create more than 5 codes" do
    user = User.create!(
      email: "limituser@example.com",
      username: "limituser",
      password: "password123"
    )
    user.ensure_invite_codes!

    # Call again - should not create more
    user.ensure_invite_codes!

    assert_equal 5, user.invites_sent.count
  end

  test "ensure_invite_codes! fills up to 5 if user has fewer" do
    user = User.create!(
      email: "partialuser@example.com",
      username: "partialuser",
      password: "password123"
    )

    # Create only 2 invites manually
    2.times { user.invites_sent.create! }
    assert_equal 2, user.invites_sent.count

    user.ensure_invite_codes!

    assert_equal 5, user.invites_sent.count
  end

  test "invite_codes returns user invites in order" do
    user = User.create!(
      email: "orderuser@example.com",
      username: "orderuser",
      password: "password123"
    )
    user.ensure_invite_codes!

    codes = user.invite_codes
    assert_equal 5, codes.count
    assert codes.first.created_at <= codes.last.created_at
  end

  test "invite code cannot be reused after being used" do
    inviter = User.create!(
      email: "inviter@example.com",
      username: "inviter",
      password: "password123"
    )
    invitee = User.create!(
      email: "invitee@example.com",
      username: "invitee",
      password: "password123"
    )

    inviter.ensure_invite_codes!
    invite = inviter.invite_codes.first

    assert invite.available?
    invite.use!(invitee)

    assert_not invite.available?
    assert_equal invitee, invite.invitee
    assert_not_nil invite.used_at

    # Try to use again
    another_user = User.create!(
      email: "another@example.com",
      username: "anotheruser",
      password: "password123"
    )
    assert_raises(RuntimeError, "Invite already used") do
      invite.use!(another_user)
    end
  end
end
