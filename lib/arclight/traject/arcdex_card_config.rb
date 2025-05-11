require_relative "json_reader"
require "logger"
require "debug"

settings do
  provide "reader_class_name", "Arclight::Traject::JsonReader"
  provide "solr_writer.commit_on_close", "true"
  provide "logger", Logger.new($stderr)
end

to_field "id", lambda { |record, accumulator| accumulator << record["id"] }

to_field "parent_ids_ssim" do |_record, accumulator, _context|
  accumulator.concat(settings[:parent].output_hash["parent_ids_ssim"] || [])
  accumulator.concat settings[:parent].output_hash["id"]
end

to_field "parent_unittitles_ssm" do |_rec, accumulator, _context|
  accumulator.concat settings[:parent].output_hash["normalized_title_ssm"] || []
end

to_field "parent_unittitles_tesim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["parent_unittitles_ssm"]
end

to_field "parent_levels_ssm" do |_record, accumulator, _context|
  accumulator.concat settings[:parent].output_hash["parent_levels_ssm"] || []
  accumulator.concat settings[:parent].output_hash["level_ssm"] || []
end

to_field "collection_ssim" do |_record, accumulator, _context|
  accumulator.concat settings[:root].output_hash["normalized_title_ssm"]
end

to_field "component_level_isim", lambda { |_record, accumulator| accumulator << (settings[:depth] || 1) }

to_field "level_ssm", lambda { |_record, accumulator| accumulator << "card" }
to_field "level_ssim", lambda { |_record, accumulator| accumulator << "Card" }

to_field "title_ssm", lambda { |record, accumulator| accumulator << record["name"] }
to_field "title_tesim", lambda { |record, accumulator| accumulator << record["name"] }
to_field "normalized_title_ssm" do |_record, accumulator, context|
  title = context.output_hash["title_ssm"]&.first
  accumulator << title
end

to_field "series_ssm", lambda { |record, accumulator| accumulator << record["set"]["series"] }
to_field "series_ssim", lambda { |record, accumulator| accumulator << record["set"]["series"] }
to_field "series_tesim", lambda { |record, accumulator| accumulator << record["set"]["series"] }

to_field "supertype_ssm", lambda { |record, accumulator| accumulator << record["supertype"] }

to_field "subtypes_ssm" do |record, accumulator|
  if record["subtypes"]
    record["subtypes"].each do |subtype|
      accumulator << subtype
    end
  end
end

to_field "level_ssi", lambda { |record, accumulator| accumulator << record["level"] if record["level"] }
to_field "hp_isi", lambda { |record, accumulator| accumulator << record["hp"] if record["hp"] }

to_field "types_ssm" do |record, accumulator|
  if record["types"]
    record["types"].each do |type|
      accumulator << type
    end
  end
end

to_field "evolves_from_ssm", lambda { |record, accumulator| accumulator << record["evolvesFrom"] if record["evolvesFrom"] }

to_field "evolves_to_ssm" do |record, accumulator|
  if record["evolvesTo"]
    record["evolvesTo"].each do |evolution|
      accumulator << evolution
    end
  end
end

to_field "abilities_json_ssm" do |record, accumulator|
  if record["abilities"]
    accumulator << record["abilities"].to_json
  end
end
to_field "ability_fields" do |record, accumulator, context|
  if record["abilities"]
    record["abilities"].each_with_index do |ability, index|
      # Create indexed field names (1-based index)
      ability_num = index + 1

      # Ability name
      context.output_hash["ability_#{ability_num}_name_tesim"] = [ ability["name"] ] if ability["name"]

      # Ability text
      context.output_hash["ability_#{ability_num}_text_tesim"] = [ ability["text"] ] if ability["text"]

      # Ability type
      context.output_hash["ability_#{ability_num}_type_tesim"] = [ ability["type"] ] if ability["type"]
    end
  end
end
to_field "number_of_abilities_isi" do |record, accumulator|
  if record["abilities"]
    accumulator << record["abilities"].length
  end
end

to_field "attacks_json_ssm" do |record, accumulator|
  if record["attacks"]
    accumulator << record["attacks"].to_json
  end
end
to_field "attack_fields" do |record, accumulator, context|
  if record["attacks"]
    record["attacks"].each_with_index do |attack, index|
      # Create indexed field names (1-based index)
      attack_num = index + 1

      # Attack name
      context.output_hash["attack_#{attack_num}_name_tesim"] = [ attack["name"] ] if attack["name"]

      # Attack cost
      if attack["cost"]
        context.output_hash["attack_#{attack_num}_cost_ssm"] = [ attack["cost"].join(", ") ]
      end

      # Converted energy cost
      if attack["convertedEnergyCost"]
        context.output_hash["attack_#{attack_num}_converted_cost_isi"] = [ attack["convertedEnergyCost"] ]
      end

      # Attack damage
      context.output_hash["attack_#{attack_num}_damage_ssm"] = [ attack["damage"] ] if attack["damage"]

      # Attack text/effect
      context.output_hash["attack_#{attack_num}_text_tesim"] = [ attack["text"] ] if attack["text"]
    end
  end

  # Also store complete attacks as JSON for flexibility
  if record["attacks"]
    context.output_hash["attacks_json_ssi"] = [ record["attacks"].to_json ]
  end
end
to_field "number_of_attacks_isi" do |record, accumulator|
  if record["attacks"]
    accumulator << record["attacks"].length
  end
end

to_field "weaknesses_json_ssm" do |record, accumulator|
  if record["weaknesses"]
    accumulator << record["weaknesses"].to_json
  end
end
to_field "weaknesses_ssm" do |record, accumulator|
  if record["weaknesses"]
    record["weaknesses"].each do |weakness|
      weakness_info = "#{weakness['type']}: #{weakness['value']}"
      accumulator << weakness_info
    end
  end
end
to_field "weakness_type_ssm" do |record, accumulator|
  if record["weaknesses"]
    record["weaknesses"].each do |weakness|
      accumulator << weakness["type"]
    end
  end
end

to_field "retreat_cost_ssm" do |record, accumulator|
  if record["retreatCost"]
    accumulator << record["retreatCost"].join(", ")
  end
end

to_field "converted_retreat_cost_isi", lambda { |record, accumulator| accumulator << record["convertedRetreatCost"].to_i }

to_field "number_ssm" do |record, accumulator|
  accumulator << "#{record["number"]}/#{settings[:complete_set_count]}"
end

to_field "sort_ssi" do |record, accumulator|
  # the api doesn't necessarily return all cards in the right order
  # ex. in set 151, Ivysaur is first and Bulbasaur is second
  number = record["number"].rjust(8, "0")
  accumulator << number
end

to_field "artist_ssm", lambda { |record, accumulator| accumulator << record["artist"] }

to_field "rarity_ssm", lambda { |record, accumulator| accumulator << record["rarity"] }

to_field "flavor_text_ssi", lambda { |record, accumulator| accumulator << record["flavorText"] }
to_field "flavor_text_tesim", lambda { |record, accumulator| accumulator << record["flavorText"] }
to_field "flavor_text_html_ssm" do |record, accumulator|
  accumulator << "<em>#{record["flavorText"]}</em>" if record["flavorText"]
end

to_field "national_pokedex_numbers_ssm" do |record, accumulator|
  if record["nationalPokedexNumbers"]
    record["nationalPokedexNumbers"].each do |number|
      accumulator << number
    end
  end
end

to_field "legalities_json_ssi" do |record, accumulator|
  if record["legalities"]
    accumulator << record["legalities"].to_json
  end
end
to_field "legalities_ssm" do |record, accumulator|
  if record["legalities"]
    record["legalities"].each do |format, status|
      accumulator << "#{format}: #{status}"
    end
  end
end

to_field "release_date_ssm" do |record, accumulator|
  if record["set"]["releaseDate"]
    # Convert from 1999/01/09 to 1999-01-09 format
    formatted_date = record["set"]["releaseDate"].gsub("/", "-")
    accumulator << formatted_date
  end
end
to_field "release_year_isi" do |_record, accumulator, context|
  context.output_hash["release_date_ssm"].each do |date|
    # Extract the year from the date string
    year = date.split("-").first.to_i
    accumulator << year if year > 0
  end
end
to_field "release_date_sort" do |record, accumulator|
  if record["set"]["releaseDate"]
    # Keep the format YYYY/MM/DD which sorts correctly as strings
    accumulator << record["set"]["releaseDate"]
  end
end

to_field "images_json_ssi" do |record, accumulator|
  if record["images"]
    accumulator << record["images"].to_json
  end
end
to_field "small_url_ssm" do |record, accumulator|
  if record["images"] && record["images"]["small"]
    accumulator << record["images"]["small"]
  end
end
to_field "small_url_html_ssm" do |record, accumulator|
  if record["images"] && record["images"]["small"]
    url = record["images"]["small"]
    accumulator << "<img src=\"#{url}\" alt=\"Card image\" class=\"small-card-image\" />"
  end
end
to_field "thumbnail_path_ssi" do |record, accumulator|
  if record["images"] && record["images"]["small"]
    accumulator << record["images"]["small"]
  end
end
to_field "large_url_ssm" do |record, accumulator|
  if record["images"] && record["images"]["large"]
    accumulator << record["images"]["large"]
  end
end
to_field "large_url_html_ssm" do |record, accumulator|
  if record["images"] && record["images"]["large"]
    url = record["images"]["large"]
    accumulator << "<img src=\"#{url}\" alt=\"Card image\" class=\"large-card-image\" />"
  end
end

to_field "tcgplayer_url_ssm" do |record, accumulator|
  if record["tcgplayer"]
    accumulator << record["tcgplayer"]["url"]
  end
end
to_field "tcgplayer_url_html_ssi" do |record, accumulator|
  if record["tcgplayer"]
    url = record["tcgplayer"]["url"]
    accumulator << "<a href=\"#{url}\" target=\"_blank\">#{url}</a>"
  end
end

to_field "cardmarket_url_ssm" do |record, accumulator|
  if record["cardmarket"]
    accumulator << record["cardmarket"]["url"]
  end
end
to_field "cardmarket_url_html_ssi" do |record, accumulator|
  if record["cardmarket"]
    url = record["cardmarket"]["url"]
    accumulator << "<a href=\"#{url}\" target=\"_blank\">#{url}</a>"
  end
end
