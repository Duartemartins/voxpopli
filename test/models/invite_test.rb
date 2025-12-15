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

  test "admin invite (no inviter) can be used multiple times" do
    admin_invite = Invite.create!(expires_at: 1.day.from_now)
    assert_nil admin_invite.inviter
    
    user1 = User.create!(
      email: "user1@example.com",
      username: "user1",
      password: "password123"
    )
    
    user2 = User.create!(
      email: "user2@example.com",
      username: "user2",
      password: "password123"
    )
    
    # First use
    assert admin_invite.available?
    admin_invite.use!(user1)
    assert admin_invite.available?
    assert_nil admin_invite.used_at
    assert_nil admin_invite.invitee
    
    # Second use
    admin_invite.use!(user2)
    assert admin_invite.available?
    assert_nil admin_invite.used_at
    assert_nil admin_invite.invitee
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

  test "use! sets invited_by on user" do
    inviter = users(:alice)
    invite = Invite.create!(inviter: inviter, expires_at: 30.days.from_now)
    user = users(:charlie)

    invite.use!(user)

    user.reload
    assert_equal inviter, user.invited_by
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

  test "available? with nil used_at and nil expires_at returns true" do
    invite = Invite.create!(inviter: users(:alice))
    invite.update_columns(used_at: nil, expires_at: nil)
    assert invite.available?
  end

  test "available? with nil used_at and future expires_at returns true" do
    invite = Invite.create!(inviter: users(:alice), expires_at: 1.week.from_now)
    assert invite.available?
  end

  test "available? with nil used_at and past expires_at returns false" do
    invite = Invite.create!(inviter: users(:alice))
    invite.update_columns(expires_at: 1.day.ago)
    assert_not invite.available?
  end

  test "available? with present used_at returns false regardless of expires_at" do
    invite = Invite.create!(inviter: users(:alice))
    invite.update_columns(used_at: Time.current, expires_at: 1.week.from_now)
    assert_not invite.available?
  end

  test "not_expired validates both conditions independently" do
    # Test invite that is both expired AND used
    invite = Invite.create!(inviter: users(:alice))
    invite.update_columns(
      used_at: 1.day.ago,
      expires_at: 1.day.ago
    )

    assert_not invite.valid?(:use)
    assert_includes invite.errors[:base], "Invite has expired"
    assert_includes invite.errors[:base], "Invite has already been used"
  end

  test "not_expired does not add errors for valid invite on use context" do
    invite = Invite.create!(inviter: users(:alice), expires_at: 1.week.from_now)
    assert invite.valid?(:use)
    assert_empty invite.errors[:base]
  end

  # New tests for updated Invite model
  test "used? returns true when used_at is present" do
    invite = invites(:used_invite)
    assert invite.used?
  end

  test "used? returns false when used_at is nil" do
    invite = invites(:available_invite)
    assert_not invite.used?
  end

  test "expired? returns true for past expires_at" do
    invite = invites(:expired_invite)
    assert invite.expired?
  end

  test "expired? returns false for future expires_at" do
    invite = invites(:available_invite)
    assert_not invite.expired?
  end

  test "expired? returns false for used invite even if expired" do
    invite = Invite.create!(inviter: users(:alice))
    invite.update_columns(used_at: 1.day.ago, expires_at: 2.days.ago)
    assert_not invite.expired?  # Used invite is not considered "expired"
  end

  test "days_until_expiry returns nil when expires_at is nil" do
    invite = invites(:no_expiry_invite)
    assert_nil invite.days_until_expiry
  end

  test "days_until_expiry returns 0 when expired" do
    invite = invites(:expired_invite)
    assert_equal 0, invite.days_until_expiry
  end

  test "days_until_expiry returns correct number of days" do
    invite = Invite.create!(inviter: users(:alice), expires_at: 5.days.from_now)
    assert_equal 5, invite.days_until_expiry
  end

  test "scope used returns only used invites" do
    used = Invite.used
    assert used.all?(&:used?)
  end

  test "scope expired returns only expired invites" do
    expired = Invite.expired
    expired.each do |invite|
      assert invite.expires_at.present?
      assert invite.expires_at <= Time.current
      assert_nil invite.used_at
    end
  end

  test "sets default expiry when inviter is present" do
    invite = Invite.create!(inviter: users(:alice))
    assert_not_nil invite.expires_at
    assert invite.expires_at > Time.current
    assert invite.expires_at <= (User::INVITE_CODE_EXPIRY_DAYS + 1).days.from_now
  end

  test "does not set default expiry when inviter is nil" do
    invite = Invite.create!
    # When no inviter, expires_at is only set if explicitly provided
    # The set_default_expiry only triggers when inviter is present
    assert_nil invite.expires_at
  end
end
