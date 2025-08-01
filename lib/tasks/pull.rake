# frozen_string_literal: true

namespace :arcdex do
  BASE_URL = 'https://api.pokemontcg.io/v2'

  desc 'Pull data from pokemontcg.io'
  task pull: :environment do
    url = "#{BASE_URL}/sets"
    puts "🌎 Fetching sets from #{url}"
    response_data = fetch_and_parse_with_retry(url)

    set_infos = response_data['data'].map do |data|
      { 'id' => data['id'], 'total' => data['total'], 'name' => data['name'] }
    end

    set_infos.each do |set_info|
      pull_set(set_info)
    end
  end

  desc 'Pull single set from pokemontcg.io'
  task pull_set: :environment do
    set_id = ENV.fetch('SET_ID', nil)
    raise 'SET_ID required' if set_id.nil?

    url = "#{BASE_URL}/sets/#{set_id}"
    puts "🌎 Fetching set from #{url}"
    response_data = fetch_and_parse_with_retry(url)
    set_info = response_data['data']
    pull_set(set_info)
  end

  def fetch_and_parse_with_retry(url, max_retries: 10, base_delay: 2) # rubocop:disable Rake/MethodDefinitionInTask
    retries = 0

    begin
      response = HTTP.get(url)

      # Check for gateway timeout or other server errors
      if response.status.server_error? || response.status == 504
        raise "❌ Server error: #{response.status}"
      end

      # Try to parse the response immediately
      parsed_response = response.parse

      # Validate that we got valid data
      unless parsed_response.is_a?(Hash)
        raise "❌ Invalid response format: expected Hash, got #{parsed_response.class}"
      end

      parsed_response

    rescue => e
      retries += 1
      if retries <= max_retries
        delay = base_delay * (2 ** (retries - 1)) # Exponential backoff: 2s, 4s, 8s, etc.
        puts "⚠️ Request/parse failed (#{e.message}). Retrying in #{delay}s... (attempt #{retries}/#{max_retries})"
        sleep(delay)
        retry
      else
        puts "❌ Request/parse failed after #{max_retries} retries.  Giving up.  Better luck tomorrow!"
        raise e
      end
    end
  end

  def pull_set(set_info) # rubocop:disable Rake/MethodDefinitionInTask
    puts "📦 Processing set: #{set_info['name']} (#{set_info['id']})"
    page = 1
    page_size = 250
    id = set_info['id']
    total_pages = (set_info['total'] / page_size.to_f).ceil

    # Gather all cards across pages
    all_cards = []

    total_pages.times do |i|
      puts "📄 Fetching page #{i+1}/#{total_pages}..."
      url = "#{BASE_URL}/cards?page=#{page}&pageSize=#{page_size}&q=set.id:#{id}"
      puts "🔗 Fetching URL: #{url}"

      begin
        # Use the combined fetch and parse method
        page_hash = fetch_and_parse_with_retry(url)

        # Extract just the cards data and add to our collection
        if page_hash && page_hash['data']
          all_cards += page_hash['data']
        end

      rescue => e
        Rails.logger.error "Failed to fetch/parse page #{i+1}/#{total_pages} after retries: #{e.message}. Skipping page."
        # Don't increment page here since we're using the loop counter
        next # Skip to the next iteration
      end

      page += 1
      sleep(0.5) # Be nice to the API
    end

    # Create the simplified structure with just data and totalCount
    simplified_data = {
      'data' => all_cards,
      'totalCount' => all_cards.size
    }

    puts "💾 Saving #{all_cards.size} cards for set #{id}"
    Rails.root.join('data', "#{id}.json").write(JSON.pretty_generate(simplified_data))
  end
end
