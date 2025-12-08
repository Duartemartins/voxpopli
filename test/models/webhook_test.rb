require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  test "valid webhook" do
    webhook = Webhook.new(
      user: users(:charlie),
      url: "https://example.com/webhook",
      events: '["post.created"]'
    )
    assert webhook.valid?
  end

  test "requires url" do
    webhook = Webhook.new(
      user: users(:charlie),
      events: '["post.created"]'
    )
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "can't be blank"
  end

  test "requires https url" do
    webhook = Webhook.new(
      user: users(:charlie),
      url: "http://example.com/webhook",
      events: '["post.created"]'
    )
    assert_not webhook.valid?
    assert_not_empty webhook.errors[:url]
  end

  test "requires valid events" do
    webhook = Webhook.new(
      user: users(:charlie),
      url: "https://example.com/webhook",
      events: '["invalid.event"]'
    )
    assert_not webhook.valid?
    assert webhook.errors[:events].any? { |e| e.include?("invalid events") }
  end

  test "requires at least one event" do
    webhook = Webhook.new(
      user: users(:charlie),
      url: "https://example.com/webhook",
      events: "[]"
    )
    assert_not webhook.valid?
    assert_includes webhook.errors[:events], "must be present"
  end

  test "generates secret on create" do
    webhook = Webhook.create!(
      user: users(:charlie),
      url: "https://example.com/webhook",
      events: '["post.created"]'
    )
    assert_not_nil webhook.secret
    assert_equal 64, webhook.secret.length
  end

  test "events_list returns parsed events" do
    webhook = webhooks(:alice_webhook)
    assert_equal [ "post.created" ], webhook.events_list
  end

  test "events_list= sets events as json" do
    webhook = Webhook.new
    webhook.events_list = [ "post.created", "post.voted" ]
    assert_equal '["post.created","post.voted"]', webhook.events
  end

  test "scope active returns only active webhooks" do
    active = Webhook.active
    active.each do |webhook|
      assert webhook.active
    end
  end

  test "all valid events are accepted" do
    Webhook::EVENTS.each do |event|
      webhook = Webhook.new(
        user: users(:charlie),
        url: "https://example.com/webhook",
        events: "[\"#{event}\"]"
      )
      assert webhook.valid?, "Event #{event} should be valid"
    end
  end
end
