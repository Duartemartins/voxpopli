require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "valid invite" do
    invite = Invite.new(inviter: users(:alice))
    assert invite.valid?
  end

  test "generates code on create" do
    invite = Invite.create!(inviter: users(:alice))
    assert_not_nil invite.code
    assert_equal 12, invite.code.length
    assert_match(/\A[A-Z0-9]+\z/, invite.code)
  end

  test "requires unique code" do
    existing = invites(:available_invite)

    duplicate = Invite.new(code: existing.code, inviter: users(:bob))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "available? returns true for unused unexpired invite" do
    invite = invites(:available_invite)
    assert invite.available?
  end

  test "available? returns false for used invite" do
    invite = invites(:used_invite)
    assert_not invite.available?
  end

  test "available? returns false for expired invite" do
    invite = invites(:expired_invite)
    assert_not invite.available?
  end

  test "available? returns true for invite with no expiry" do
    invite = invites(:no_expiry_invite)
    assert invite.available?
  end

  test "scope available returns only available invites" do
    available = Invite.available

    available.each do |invite|
      assert invite.available?
    end
  end

  test "use! marks invite as used" do
    invite = invites(:available_invite)
    user = users(:charlie)

    assert_nil invite.invitee
    assert_nil invite.used_at

    invite.use!(user)

    invite.reload
    assert_equal user, invite.invitee
    assert_not_nil invite.used_at
    assert_not invite.available?
  end

  test "use! raises error if already used" do
    invite = invites(:used_invite)

    assert_raises RuntimeError do
      invite.use!(users(:charlie))
    end
  end

  test "use! validates not expired on use context" do
    invite = invites(:expired_invite)

    assert_raises RuntimeError do
      invite.use!(users(:charlie))
    end
  end
end
