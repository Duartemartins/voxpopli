class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 5

  def perform(webhook_id, event, payload)
    webhook = Webhook.find(webhook_id)
    return unless webhook.active?

    signature = OpenSSL::HMAC.hexdigest("sha256", webhook.secret, payload.to_json)

    uri = URI(webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["X-Webhook-Signature"] = "sha256=#{signature}"
    request["X-Webhook-Event"] = event
    request.body = payload.to_json

    response = http.request(request)

    webhook.update!(last_triggered_at: Time.current, last_status: response.code.to_i)
  end
end
