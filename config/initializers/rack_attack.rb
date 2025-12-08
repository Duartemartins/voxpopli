class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Safelist localhost
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # API rate limit by IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Login throttle
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end

  # Registration throttle
  throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Block bad actors
  blocklist('block-bad-requests') do |req|
    Rack::Attack::Fail2Ban.filter("badreq-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      req.path.include?('.php') || req.path.include?('wp-admin')
    end
  end

  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [429, { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
     [{ error: 'Rate limit exceeded', retry_after: retry_after }.to_json]]
  end
end
