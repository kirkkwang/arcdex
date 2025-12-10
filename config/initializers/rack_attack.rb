class Rack::Attack
  # Block all bots from /catalog by user agent
  blocklist('block bots from catalog') do |req|
    req.path.start_with?('/catalog') &&
    req.user_agent.to_s =~ /bot|crawler|spider|scraper/i
  end

  # Block fake old Windows user agents
  blocklist('block fake old Windows user agents') do |req|
    req.user_agent.to_s =~ /Windows NT (5\.1|6\.[0-2])/i
  end
end
