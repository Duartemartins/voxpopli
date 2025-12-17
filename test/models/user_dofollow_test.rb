require "test_helper"

class UserDofollowTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test_dofollow@example.com",
      username: "test_dofollow",
      password: "password123",
      confirmed_at: Time.current
    )
    @theme = Theme.create!(name: "Test Theme", slug: "test-theme", color: "#000000")
  end

  test "user is not eligible initially" do
    assert_not @user.has_replied?
    assert_not @user.has_posted?
    assert_not @user.has_voted?
    assert_not @user.has_followed?
    assert_not @user.dofollow_eligible?
  end

  test "user becomes eligible after completing all tasks" do
    # 1. Post (Transmission)
    post = Post.create!(user: @user, body: "Hello world", theme: @theme)
    assert @user.has_posted?
    assert_not @user.dofollow_eligible?

    # 2. Reply
    other_user = User.create!(
      email: "other@example.com",
      username: "other_user",
      password: "password123",
      confirmed_at: Time.current
    )
    other_post = Post.create!(user: other_user, body: "Other post", theme: @theme)

    Post.create!(user: @user, body: "Great post!", parent: other_post)
    assert @user.has_replied?
    assert_not @user.dofollow_eligible?

    # 3. Vote
    Vote.create!(user: @user, post: other_post)
    assert @user.has_voted?
    assert_not @user.dofollow_eligible?

    # 4. Follow
    Follow.create!(follower: @user, followed: other_user)
    assert @user.has_followed?

    # Should be eligible now
    assert @user.dofollow_eligible?
  end
end
