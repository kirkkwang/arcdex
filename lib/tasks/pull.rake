# frozen_string_literal: true

namespace :arcdex do
  POKEMON_TCG_IO_BASE_URL = 'https://api.pokemontcg.io/v2'
  TCGDEX_BASE_URL = 'https://api.tcgdex.net/v2'
  TCGDEX_LANGUAGE = 'en'

  desc 'Pull data from pokemontcg.io'
  task pull: :environment do
    url = "#{POKEMON_TCG_IO_BASE_URL}/sets"
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

    url = "#{POKEMON_TCG_IO_BASE_URL}/sets/#{set_id}"
    puts "🌎 Fetching set from #{url}"
    response_data = fetch_and_parse_with_retry(url)
    set_info = response_data['data']
    pull_set(set_info)
  end

  desc 'Pull Pokémon TCG Pocket data from TCGdex'
  task pull_pocket: :environment do
    puts '🎮 Fetching Pokémon TCG Pocket series...'
    url = "#{TCGDEX_BASE_URL}/#{TCGDEX_LANGUAGE}/series/tcgp"

    response_data = fetch_and_parse_with_retry(url)

    set_ids = response_data['sets'].pluck('id')
    puts "📦 Found #{set_ids.length} Pocket sets: #{set_ids.join(', ')}"

    set_ids.each do |set_id|
      pull_pocket_set(set_id)
    end
  end

  desc 'Pull single Pocket set from TCGdex'
  task pull_pocket_set: :environment do
    set_id = ENV.fetch('SET_ID', nil)
    raise 'SET_ID required (e.g., A1, A1a, B1)' if set_id.nil?

    pull_pocket_set(set_id)
  end

  def pull_pocket_set(set_id) # rubocop:disable Rake/MethodDefinitionInTask
    puts "\n📦 Processing Pocket set: #{set_id}"

    # Get set info with brief card list
    set_url = "#{TCGDEX_BASE_URL}/#{TCGDEX_LANGUAGE}/sets/#{set_id}"
    puts "🌎 Fetching set from #{set_url}"
    set_data = fetch_and_parse_with_retry(set_url)

    puts "📋 Set: #{set_data['name']}"
    puts "📊 Total cards: #{set_data['cardCount']['total']}"

    # Check if booster data exists
    if set_data['boosters']
      puts "🎲 Boosters: #{set_data['boosters'].pluck('name').join(', ')}"
    else
      puts "⚠️  No booster data available for #{set_id} yet"
    end

    card_ids = set_data['cards'].pluck('id')
    puts "🃏 Fetching full details for #{card_ids.length} cards..."

    # Fetch all cards concurrently
    full_cards = fetch_cards_concurrently(card_ids)

    # Replace brief cards with full data
    set_data['cards'] = full_cards

    # Save to file
    output_path = Rails.root.join('data', 'pocket', "#{set_id}.json")
    output_path.dirname.mkpath # Create pocket directory if needed

    puts "💾 Saving to #{output_path}"
    output_path.write(JSON.pretty_generate(set_data))

    puts "✅ Done! Saved #{full_cards.length} cards for #{set_id}"
  end

  def fetch_cards_concurrently(card_ids, max_concurrent: 15) # rubocop:disable Rake/MethodDefinitionInTask
    require 'concurrent'

    pool = Concurrent::FixedThreadPool.new(max_concurrent)

    promises = card_ids.map do |card_id|
      Concurrent::Promise.execute(executor: pool) do
        url = "#{TCGDEX_BASE_URL}/#{TCGDEX_LANGUAGE}/cards/#{card_id}"
        fetch_and_parse_with_retry(url)
      end
    end

    # Wait for all to complete
    results = promises.map(&:value!)
    pool.shutdown
    pool.wait_for_termination

    results
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
      url = "#{POKEMON_TCG_IO_BASE_URL}/cards?page=#{page}&pageSize=#{page_size}&q=set.id:#{id}"
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

    # Validate we got data before saving
    if all_cards.empty?
      puts "⚠️  WARNING: No cards fetched for set #{id} (#{set_info['name']}). Skipping save to preserve existing data."
      return
    end

    # Create the simplified structure with just data and totalCount
    simplified_data = {
      'data' => all_cards,
      'totalCount' => all_cards.size
    }

    output_path = Rails.root.join('data', "#{id}.json")

    # Check if file exists and compare counts
    if output_path.exist?
      existing_data = JSON.parse(output_path.read)
      existing_count = existing_data['totalCount'] || 0

      if all_cards.size < existing_count
        puts "⚠️  WARNING: New data has fewer cards (#{all_cards.size}) than existing (#{existing_count}). Skipping save."
        return
      end
    end

    puts "💾 Saving #{all_cards.size} cards for set #{id}"
    output_path.write(JSON.pretty_generate(simplified_data))
  end
end
