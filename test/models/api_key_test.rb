require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  test "valid api key" do
    api_key = ApiKey.new(
      user: users(:charlie),
      name: "Test Key"
    )
    assert api_key.valid?
  end

  test "requires name" do
    api_key = ApiKey.new(user: users(:charlie))
    assert_not api_key.valid?
    assert_includes api_key.errors[:name], "can't be blank"
  end

  test "generates key on create" do
    api_key = ApiKey.create!(
      user: users(:charlie),
      name: "New Key"
    )

    assert_not_nil api_key.raw_key
    assert api_key.raw_key.start_with?("bb_live_")
    assert_not_nil api_key.key_prefix
    assert_not_nil api_key.key_digest
  end

  test "raw_key is only available after create" do
    api_key = ApiKey.create!(
      user: users(:charlie),
      name: "New Key"
    )
    _raw = api_key.raw_key

    reloaded = ApiKey.find(api_key.id)
    assert_nil reloaded.raw_key
    assert_equal api_key.key_prefix, reloaded.key_prefix
  end

  test "authenticate returns nil for invalid token" do
    assert_nil ApiKey.authenticate(nil)
    assert_nil ApiKey.authenticate("")
    assert_nil ApiKey.authenticate("invalid_token")
  end

  test "increment_usage! increments counter and updates last_used_at" do
    api_key = api_keys(:alice_api_key)
    initial_count = api_key.requests_count

    api_key.increment_usage!

    api_key.reload
    assert_equal initial_count + 1, api_key.requests_count
    assert_not_nil api_key.last_used_at
  end

  test "rate_limit_exceeded? returns true when over limit" do
    limited = api_keys(:bob_rate_limited)
    assert limited.rate_limit_exceeded?

    normal = api_keys(:alice_api_key)
    assert_not normal.rate_limit_exceeded?
  end
end
