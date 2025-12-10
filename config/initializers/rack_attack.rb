class Rack::Attack
  # Block all bots from /catalog
  blocklist('block bots from catalog') do |req|
    req.path.start_with?('/catalog') &&
    req.user_agent.to_s =~ /bot|crawler|spider|scraper/i
  end
end
