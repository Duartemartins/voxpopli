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

  test "requires code presence" do
    invite = Invite.new(inviter: users(:alice))
    invite.code = nil
    # Force validation without triggering before_validation callback
    invite.instance_variable_set(:@_skip_generate_code, true)

    # Since generate_code sets code on create, we need to test after create
    # by manually clearing it
    invite.save!
    invite.code = nil
    assert_not invite.valid?
    assert_includes invite.errors[:code], "can't be blank"
  end

  test "does not overwrite existing code on create" do
    custom_code = "MYCUSTOMCODE1"
    invite = Invite.create!(code: custom_code, inviter: users(:alice))
    assert_equal custom_code, invite.code
  end

  test "available? returns true for invite with future expiry" do
    invite = Invite.create!(
      inviter: users(:alice),
      expires_at: 1.week.from_now
    )
    assert invite.available?
  end

  test "not_expired validation adds expired error on use context" do
    invite = Invite.create!(
      inviter: users(:alice),
      expires_at: 1.day.ago
    )
    assert_not invite.valid?(:use)
    assert_includes invite.errors[:base], "Invite has expired"
  end

  test "not_expired validation adds already used error on use context" do
    invite = invites(:used_invite)
    assert_not invite.valid?(:use)
    assert_includes invite.errors[:base], "Invite has already been used"
  end

  test "scope available excludes used invites" do
    used_invite = invites(:used_invite)
    assert_not_includes Invite.available, used_invite
  end

  test "scope available excludes expired invites" do
    expired_invite = invites(:expired_invite)
    assert_not_includes Invite.available, expired_invite
  end

  test "scope available includes invites with future expiry" do
    future_invite = Invite.create!(
      inviter: users(:alice),
      expires_at: 1.week.from_now
    )
    assert_includes Invite.available, future_invite
  end

  test "scope available includes invites with no expiry" do
    no_expiry_invite = invites(:no_expiry_invite)
    assert_includes Invite.available, no_expiry_invite
  end

  test "inviter association is optional" do
    invite = Invite.create!
    assert_nil invite.inviter
    assert invite.valid?
  end

  test "invitee association is optional" do
    invite = Invite.create!(inviter: users(:alice))
    assert_nil invite.invitee
    assert invite.valid?
  end
end
