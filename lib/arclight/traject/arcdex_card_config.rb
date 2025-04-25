require "logger"
require "traject"
require "traject_plus"
require "traject_plus/macros"
require "json"
require "arclight/traject/json_reader"

# rubocop:disable Style/MixinUsage
extend TrajectPlus::Macros
# rubocop:enable Style/MixinUsage

settings do
  provide "reader_class_name", "Arclight::Traject::JsonReader"
  provide "solr_writer.commit_on_close", "true"
  provide "logger", Logger.new($stderr)
end

# ==================
# Basic field mapping
# ==================

# ID field
to_field "id", lambda { |record, accumulator| accumulator << record["id"] }

# Establish relationships with the set "collection"
to_field "collection_ssim" do |record, accumulator|
  accumulator << record["set"]["name"]
end

to_field "parent_ssim" do |record, accumulator|
  accumulator << record["set"]["id"]
end

to_field "parent_ssi" do |record, accumulator|
  accumulator << record["set"]["id"]
end

# Mark these as component-level records
to_field "level_ssm", lambda { |_record, accumulator| accumulator << "card" }
to_field "level_ssim", lambda { |_record, accumulator| accumulator << "Card" }

# Add title fields (from the 'name' property)
to_field "title_ssm", lambda { |record, accumulator| accumulator << record["name"] }
to_field "title_tesim", lambda { |record, accumulator| accumulator << record["name"] }
to_field "normalized_title_ssm" do |_record, accumulator, context|
  title = context.output_hash["title_ssm"]&.first
  accumulator << title
end

to_field "supertype_ssm", lambda { |record, accumulator| accumulator << record["supertype"] }

to_field "subtypes_ssm" do |record, accumulator|
  if record["subtypes"]
    record["subtypes"].each do |subtype|
      accumulator << subtype
    end
  end
end

to_field "hp_ssm", lambda { |record, accumulator| accumulator << record["hp"] if record["hp"] }

to_field "types_ssm" do |record, accumulator|
  if record["types"]
    record["types"].each do |type|
      accumulator << type
    end
  end
end

to_field "evolvesTo_ssm" do |record, accumulator|
  if record["evolvesTo"]
    record["evolvesTo"].each do |evolution|
      accumulator << evolution
    end
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
      context.output_hash["attack_#{attack_num}_name_ssm"] = [ attack["name"] ] if attack["name"]

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
      context.output_hash["attack_#{attack_num}_text_ssm"] = [ attack["text"] ] if attack["text"]
    end
  end

  # Also store complete attacks as JSON for flexibility
  if record["attacks"]
    context.output_hash["attacks_json_ssi"] = [ record["attacks"].to_json ]
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

to_field "retreat_cost_ssm" do |record, accumulator|
  if record["retreatCost"]
    accumulator << record["retreatCost"].join(", ")
  end
end

to_field "converted_retreat_cost_isi", lambda { |record, accumulator| accumulator << record["convertedRetreatCost"].to_i }

to_field "number_ssm", lambda { |record, accumulator| accumulator << record["number"] }

to_field "artist_ssm", lambda { |record, accumulator| accumulator << record["artist"] }

to_field "rarity_ssm", lambda { |record, accumulator| accumulator << record["rarity"] }

to_field "flavor_text_ssim", lambda { |record, accumulator| accumulator << record["flavorText"] }

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
to_field "large_url_ssm" do |record, accumulator|
  if record["images"] && record["images"]["large"]
    accumulator << record["images"]["large"]
  end
end

to_field "tcgplayer_url_ssm" do |record, accumulator|
  if record["tcgplayer"]
    accumulator << record["tcgplayer"]["url"]
  end
end

to_field "cardmarket_url_ssm" do |record, accumulator|
  if record["cardmarket"]
    accumulator << record["cardmarket"]["url"]
  end
end

# Nesting fields for component display
to_field "_nest_path_", lambda { |record, accumulator| accumulator << "#{record['set']['id']}/#{record['id']}" }
to_field "_nest_parent_", lambda { |record, accumulator| accumulator << record["set"]["id"] }

# Component level (1 = direct child of collection)
to_field "component_level_isim", lambda { |_record, accumulator| accumulator << 1 }

# Sort field for display order
to_field "sort_isi" do |record, accumulator|
  # Try to use the card number for sorting if it's numeric
  if record['number'] =~ /^\d+$/
    accumulator << record['number'].to_i
  else
    # Otherwise fall back to string order
    accumulator << record['number'].to_s
  end
end
