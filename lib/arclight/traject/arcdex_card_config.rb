require_relative 'json_reader'
require 'logger'
require 'debug'

settings do
  provide 'reader_class_name', 'Arclight::Traject::JsonReader'
  provide 'solr_writer.commit_on_close', 'true'
  provide 'logger', Logger.new($stderr)
end

factory = Arcdex::CardAdapterFactory

to_field 'id', lambda { |record, accumulator| accumulator << factory.call(record).id }

to_field 'parent_ids_ssim' do |_record, accumulator, _context|
  accumulator.concat(settings[:parent].output_hash['parent_ids_ssim'] || [])
  accumulator.concat settings[:parent].output_hash['id']
end

to_field 'parent_unittitles_ssm' do |_rec, accumulator, _context|
  accumulator.concat settings[:parent].output_hash['normalized_title_ssm'] || []
end

to_field 'parent_unittitles_tesim' do |_record, accumulator, context|
  accumulator.concat context.output_hash['parent_unittitles_ssm']
end

to_field 'parent_levels_ssm' do |_record, accumulator, _context|
  accumulator.concat settings[:parent].output_hash['parent_levels_ssm'] || []
  accumulator.concat settings[:parent].output_hash['level_ssm'] || []
end

to_field 'collection_ssim' do |_record, accumulator, _context|
  accumulator.concat settings[:root].output_hash['normalized_title_ssm']
end

to_field 'component_level_isim', lambda { |_record, accumulator| accumulator << (settings[:depth] || 1) }

to_field 'level_ssm', lambda { |_record, accumulator| accumulator << 'card' }
to_field 'level_ssim', lambda { |_record, accumulator| accumulator << 'Card' }

to_field 'has_online_content_ssim', lambda { |_record, accumulator| accumulator << settings[:has_online_content] }

to_field 'title_ssm', lambda { |record, accumulator| accumulator << record['name'] }
to_field 'title_tesim', lambda { |record, accumulator| accumulator << record['name'] }
to_field 'normalized_title_ssm' do |_record, accumulator, context|
  title = context.output_hash['title_ssm']&.first
  accumulator << title
end

to_field 'series_ssm', lambda { |record, accumulator| accumulator << factory.call(record).series }
to_field 'series_ssim', lambda { |record, accumulator| accumulator << factory.call(record).series }
to_field 'series_tesim', lambda { |record, accumulator| accumulator << factory.call(record).series }

to_field 'supertype_ssm', lambda { |record, accumulator| accumulator << factory.call(record).supertype }

to_field 'subtypes_ssm' do |record, accumulator|
  factory.call(record).subtypes.each do |subtype|
    accumulator << subtype
  end
end

to_field 'level_ssi', lambda { |record, accumulator| accumulator << factory.call(record).level }

to_field 'hp_isi', lambda { |record, accumulator| accumulator << factory.call(record).hp }

to_field 'types_ssm' do |record, accumulator|
  factory.call(record).types.each do |type|
    accumulator << type
  end
end

to_field 'evolves_from_ssm', lambda { |record, accumulator| accumulator << factory.call(record).evolves_from }

to_field 'evolves_to_ssm' do |record, accumulator|
  factory.call(record).evolves_to.each do |evolution|
    accumulator << evolution
  end
end

to_field 'abilities_json_ssm', lambda { |record, accumulator| accumulator << factory.call(record).abilities_json }
to_field 'ability_fields' do |record, accumulator, context|
  factory.call(record).abilities&.each_with_index do |ability, index|
    # Create indexed field names (1-based index)
    ability_num = index + 1

    # Ability name
    context.output_hash["ability_#{ability_num}_name_tesim"] = [factory.call(record).ability_name(index)]

    # Ability text
    context.output_hash["ability_#{ability_num}_text_tesim"] = [factory.call(record).ability_text(index)]

    # Ability type
    context.output_hash["ability_#{ability_num}_type_tesim"] = [factory.call(record).ability_type(index)]
  end
end
to_field 'number_of_abilities_isi', lambda { |record, accumulator| accumulator << factory.call(record).abilities&.size }

to_field 'attacks_json_ssm', lambda { |record, accumulator| accumulator << factory.call(record).attacks_json }
to_field 'attack_fields' do |record, accumulator, context|
  factory.call(record).attacks&.each_with_index do |attack, index|
    # Create indexed field names (1-based index)
    attack_num = index + 1

    # Attack name
    context.output_hash["attack_#{attack_num}_name_tesim"] = [factory.call(record).attack_name(index)]

    # Attack cost
    context.output_hash["attack_#{attack_num}_cost_ssm"] = [factory.call(record).attack_cost(index).join(', ')]

    # Converted energy cost
    context.output_hash["attack_#{attack_num}_converted_cost_isi"] = [factory.call(record).attack_converted_energy_cost(index)]

    # Attack damage
    context.output_hash["attack_#{attack_num}_damage_ssm"] = [factory.call(record).attack_damage(index)] if factory.call(record).attack_damage(index)
    # Attack text/effect
    context.output_hash["attack_#{attack_num}_text_tesim"] = [factory.call(record).attack_text(index)] if factory.call(record).attack_text(index)
  end

  # Also store complete attacks as JSON for flexibility
  context.output_hash['attacks_json_ssi'] = [factory.call(record).attacks.to_json]
end
to_field 'number_of_attacks_isi', lambda { |record, accumulator| accumulator << factory.call(record).attacks&.size }

to_field 'weaknesses_json_ssm', lambda { |record, accumulator| accumulator << factory.call(record).weaknesses_json }
to_field 'weaknesses_ssm' do |record, accumulator|
  factory.call(record).weaknesses&.each_with_index do |weakness, index|
    weakness_info = "#{factory.call(record).weakness_type(index)}: #{factory.call(record).weakness_value(index)}"
    accumulator << weakness_info
  end
end
to_field 'weakness_type_ssm' do |record, accumulator|
  if factory.call(record).weaknesses&.any?
    factory.call(record).weaknesses&.each_with_index do |weakness, index|
      accumulator << factory.call(record).weakness_type(index)
    end
  else
    accumulator << 'None' if factory.call(record).supertype == 'Pokémon'
  end
end

to_field 'retreat_cost_ssm', lambda { |record, accumulator| accumulator << factory.call(record).retreat_cost }

to_field 'converted_retreat_cost_isi', lambda { |record, accumulator| accumulator << factory.call(record).converted_retreat_cost }

to_field 'number_ssm' do |record, accumulator|
  complete_set_count = settings[:complete_set_count]
  accumulator << "#{factory.call(record).number}/#{complete_set_count}"
end
to_field 'number_tesim' do |record, accumulator|
  complete_set_count = settings[:complete_set_count]
  accumulator << "#{factory.call(record).number}/#{complete_set_count}"
end
to_field 'number_no_set_tesim' do |record, accumulator|
  complete_set_count = settings[:complete_set_count]
  accumulator << factory.call(record).number
end

to_field 'sort_ssi' do |record, accumulator|
  # the api doesn't necessarily return all cards in the right order
  # ex. in set 151, Ivysaur is first and Bulbasaur is second
  accumulator << factory.call(record).number.to_s.rjust(8, '0')
end

to_field 'artist_ssm', lambda { |record, accumulator| accumulator << factory.call(record).artist }
to_field 'artist_tesim', lambda { |record, accumulator| accumulator << factory.call(record).artist }

to_field 'rarity_ssm', lambda { |record, accumulator| accumulator << factory.call(record).rarity }

to_field 'regulation_mark_tesim', lambda { |record, accumulator| accumulator << factory.call(record).regulation_mark }
to_field 'regulation_mark_ssi', lambda { |record, accumulator| accumulator << factory.call(record).regulation_mark }

to_field 'flavor_text_ssi', lambda { |record, accumulator| accumulator << factory.call(record).flavor_text }
to_field 'flavor_text_tesim', lambda { |record, accumulator| accumulator << factory.call(record).flavor_text }
to_field 'flavor_text_html_ssm' do |record, accumulator|
  accumulator << "<em>#{factory.call(record).flavor_text}</em>" if factory.call(record).flavor_text
end

to_field 'national_pokedex_numbers_isim', lambda { |record, accumulator| accumulator.concat(factory.call(record).national_pokedex_numbers) }

to_field 'legalities_json_ssi', lambda { |record, accumulator| accumulator << factory.call(record).legalities_json }
to_field 'legalities_ssm' do |record, accumulator|
  factory.call(record).legalities&.each do |format, status|
    accumulator << "#{format}: #{status}"
  end
end

to_field 'release_date_ssm' do |record, accumulator|
  accumulator << settings[:release_date]
end
to_field 'release_year_isi' do |_record, accumulator, context|
  context.output_hash['release_date_ssm'].each do |date|
    # Extract the year from the date string
    year = date.split('-').first.to_i
    accumulator << year if year > 0
  end
end
to_field 'release_date_sort' do |record, accumulator|
  # Keep the format YYYY/MM/DD which sorts correctly as strings
  # Append set ID to ensure the set is grouped together even in all results view
  accumulator << (settings[:release_date] + settings[:set_id]) if settings[:release_date]
end

to_field 'images_json_ssi', lambda { |record, accumulator| accumulator << factory.call(record).images_json }
to_field 'small_url_ssm', lambda { |record, accumulator| accumulator << factory.call(record).small_image }
to_field 'small_url_html_ssm' do |record, accumulator|
  url = factory.call(record).small_image
  accumulator << "<img src=\"#{url}\" alt=\"Card image\" class=\"small-card-image\" />"
end
to_field 'thumbnail_path_ssi', lambda { |record, accumulator| accumulator << factory.call(record).small_image }
to_field 'large_url_ssm', lambda { |record, accumulator| accumulator << factory.call(record).large_image }
to_field 'large_url_html_ssm' do |record, accumulator|
  url = factory.call(record).large_image
  accumulator << "<img src=\"#{url}\" alt=\"Card image\" class=\"large-card-image\" />"
end

to_field 'tcg_player_url_ssi', lambda { |record, accumulator| accumulator << factory.call(record).tcg_player_price_url }
to_field 'tcg_player_market_price_isi' do |record, accumulator|
  if factory.call(record).tcgplayer && factory.call(record).tcgplayer_prices
    prices_keys = factory.call(record).tcgplayer_prices.keys
    prices = []
    prices_keys.each do |price_type|
      if factory.call(record).tcgplayer_prices[price_type]
        price_info = factory.call(record).tcgplayer_prices[price_type]
        prices << price_info['market']
      end
    end
    accumulator << prices.compact&.max
  end
end
to_field 'tcg_player_price_updated_at_ssi' do |record, accumulator|
  if factory.call(record).tcgplayer && factory.call(record).tcgplayer_updated_at
    formatted_date = factory.call(record).tcgplayer_updated_at
    accumulator << formatted_date
  end
end
to_field 'tcg_player_prices_json_ssi' do |record, accumulator|
  if factory.call(record).tcgplayer && factory.call(record).tcgplayer_prices
    accumulator << factory.call(record).tcgplayer_prices.to_json
  end
end

to_field 'cardmarket_url_ssi', lambda { |record, accumulator| accumulator << factory.call(record).cardmarket_url }
to_field 'cardmarket_avg7_price_isi' do |record, accumulator|
  if factory.call(record).cardmarket && factory.call(record).cardmarket_prices && factory.call(record).cardmarket_prices['avg7']
    accumulator << factory.call(record).cardmarket_avg7_price
  end
end
to_field 'cardmarket_price_updated_at_ssi' do |record, accumulator|
  if factory.call(record).cardmarket && factory.call(record).cardmarket_updated_at
    formatted_date = factory.call(record).cardmarket_updated_at
    accumulator << formatted_date
  end
end
to_field 'cardmarket_prices_json_ssi' do |record, accumulator|
  if factory.call(record).cardmarket && factory.call(record).cardmarket_prices
    accumulator << factory.call(record).cardmarket_prices_json
  end
end

to_field 'boosters_tesim' do |record, accumulator|
  accumulator.concat factory.call(record).boosters if factory.call(record).boosters
end
