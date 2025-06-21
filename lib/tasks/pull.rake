# frozen_string_literal: true

namespace :arcdex do
  desc 'Pull data from pokemontcg.io'
  task pull: :environment do
    BASE_URL = 'https://api.pokemontcg.io/v2'
    response = HTTP.get("#{BASE_URL}/sets")
    set_infos = response.parse['data'].map do |data|
      { id: data['id'], total: data['total'], name: data['name'] }
    end

    set_infos.each do |set_info|
      puts "Processing set: #{set_info[:name]} (#{set_info[:id]})"
      page = 1
      page_size = 250
      id = set_info[:id]
      total_pages = (set_info[:total] / page_size.to_f).ceil

      # Gather all cards across pages
      all_cards = []

      total_pages.times do |i|
        puts "  Fetching page #{i+1}/#{total_pages}..."
        r = HTTP.get("#{BASE_URL}/cards?page=#{page}&pageSize=#{page_size}&q=set.id:#{id}")

        begin
          retries ||= 0
          page_hash = r.parse
        rescue => e
          Rails.logger.error "Error parsing response: #{e.message}"
          if (retries += 1) < 3
            sleep(5) # Wait a bit before retrying
            retry
          else
            Rails.logger.error "Failed to parse response after 3 retries for page #{i+1}/#{total_pages}. Skipping page."
            page += 1
            next # Skip to the next iteration
          end
        end

        # Extract just the cards data and add to our collection
        if page_hash && page_hash['data']
          all_cards += page_hash['data']
        end

        page += 1
        sleep(0.5) # Be nice to the API
      end

      # Create the simplified structure with just data and totalCount
      simplified_data = {
        'data' => all_cards,
        'totalCount' => all_cards.size
      }

      puts "  Saving #{all_cards.size} cards for set #{id}"
      Rails.root.join('data', "#{id}.json").write(JSON.pretty_generate(simplified_data))
    end
  end
end
