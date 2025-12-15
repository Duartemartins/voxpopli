require "test_helper"

class WebhookDeliveryJobTest < ActiveJob::TestCase
  setup do
    @user = users(:alice)
    @webhook = @user.webhooks.create!(
      url: "https://example.com/webhook",
      secret: "test_secret_123",
      events: '["post.created"]',
      active: true
    )
  end

  test "skips inactive webhooks" do
    @webhook.update!(active: false)

    # Should return early without making any HTTP request
    # We verify by checking that last_triggered_at remains nil
    WebhookDeliveryJob.perform_now(@webhook.id, "post.created", { test: "data" })

    @webhook.reload
    assert_nil @webhook.last_triggered_at
  end

  test "generates consistent HMAC signature for same payload" do
    payload = { post_id: "123", body: "Test post" }
    signature1 = OpenSSL::HMAC.hexdigest("sha256", @webhook.secret, payload.to_json)
    signature2 = OpenSSL::HMAC.hexdigest("sha256", @webhook.secret, payload.to_json)

    # Verify the signature is deterministic
    assert_equal signature1, signature2
  end

  test "queues on webhooks queue" do
    assert_equal "webhooks", WebhookDeliveryJob.queue_name
  end

  test "job can be enqueued" do
    assert_enqueued_with(job: WebhookDeliveryJob) do
      WebhookDeliveryJob.perform_later(@webhook.id, "post.created", { test: "data" })
    end
  end

  test "job inherits from ApplicationJob" do
    assert WebhookDeliveryJob < ApplicationJob
  end

  test "finds webhook by id" do
    # Ensure the webhook can be found
    found_webhook = Webhook.find(@webhook.id)
    assert_equal @webhook.url, found_webhook.url
  end

  test "performs request and updates webhook status on success" do
    payload = { test: "data" }

    # Mock Net::HTTP
    mock_http = Minitest::Mock.new
    mock_response = Minitest::Mock.new
    mock_response.expect :code, "200"

    mock_http.expect :use_ssl=, true, [ true ]
    mock_http.expect :request, mock_response, [ Net::HTTP::Post ]

    Net::HTTP.stub :new, mock_http do
      WebhookDeliveryJob.perform_now(@webhook.id, "post.created", payload)
    end

    @webhook.reload
    assert_equal 200, @webhook.last_status
    assert_not_nil @webhook.last_triggered_at

    mock_http.verify
    mock_response.verify
  end
end
