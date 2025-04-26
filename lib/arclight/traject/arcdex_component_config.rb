require 'debug'

settings do
  provide 'component_traject_config', __FILE__
  provide 'logger', Logger.new($stderr)
  provide 'component_identifier_format', '%<root_id>s_%<ref_id>s'
  provide "reader_class_name", "Traject::NokogiriReader"
end

# ==================
# Component elements
#
# NOTE: All fields should be stored in Solr
# ==================

to_field 'level_ssm' do |record, accumulator|
  accumulator << record.attribute('level')&.value
end

to_field 'child_component_count_isi' do |record, accumulator|
  accumulator << record.xpath('c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12').count
end

to_field 'ref_ssi' do |record, accumulator, context|
  next if context.output_hash['ref_ssi']

  accumulator << record.attribute('id')&.value&.strip&.gsub('.', '-')
end

to_field 'ref_ssm' do |_record, accumulator, context|
  accumulator.concat context.output_hash['ref_ssi']
end

to_field 'id' do |_record, accumulator, context|
  next if context.output_hash['id']

  data = {
    root_id: settings[:root].output_hash['id']&.first,
    ref_id: context.output_hash['ref_ssi']&.first
  }

  accumulator << (settings[:component_identifier_format] % data)
end

to_field 'title_ssm', extract_xpath('./name')
to_field 'title_tesim', extract_xpath('./name')

to_field 'normalized_title_ssm' do |_record, accumulator, context|
  accumulator << context.output_hash['title_ssm']&.first
end

to_field 'supertype_ssm', extract_xpath('./supertype')

to_field 'subtypes_ssm' do |record, accumulator, _context|
  record.xpath('./subtypes').each do |node|
    accumulator << node&.text
  end
end

to_field 'level_ssi', extract_xpath('./level')

to_field 'hp_ssi', extract_xpath('./hp')

to_field 'types_ssm' do |record, accumulator, _context|
  record.xpath('./types').each do |node|
    accumulator << node&.text
  end
end

to_field 'evolves_from_ssi', extract_xpath('./evolves_from')

to_field 'abilities_ssm' do |record, accumulator, _context|
  record.xpath('./abilities').each do |ability_node|
    ability = {}

    # Process all child elements dynamically
    ability_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      ability[child.name] = child.text.strip
    end

    accumulator << ability.to_json unless ability.empty?
  end
end

to_field 'attacks_ssm' do |record, accumulator, _context|
  record.xpath('./attacks').each do |attack_node|
    attack = {}

    # Create a counter to track how many times we've seen each key
    key_counts = Hash.new(0)

    # Process all child elements dynamically
    attack_node.element_children.each do |child|
      key = child.name
      key_counts[key] += 1

      # Special handling for 'cost' elements which can appear multiple times
      if key == 'cost'
        # Initialize cost array if this is the first cost element
        attack['cost'] ||= []
        attack['cost'] << child.text.strip
      else
        # For numeric fields, convert to integer
        if ['converted_energy_cost', 'converted_retreat_cost'].include?(key)
          attack[key] = child.text.strip.to_i
        else
          # For all other elements, just use the text value
          attack[key] = child.text.strip
        end
      end
    end

    accumulator << attack.to_json unless attack.empty?
  end
end

to_field 'weaknesses_ssm' do |record, accumulator, _context|
  record.xpath('./weaknesses').each do |weakness_node|
    weakness = {}

    # Process all child elements dynamically
    weakness_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      weakness[child.name] = child.text.strip
    end

    accumulator << weakness.to_json unless weakness.empty?
  end
end

to_field 'resistances_ssm' do |record, accumulator, _context|
  record.xpath('./resistances').each do |resistance_node|
    resistance = {}

    # Process all child elements dynamically
    resistance_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      resistance[child.name] = child.text.strip
    end

    accumulator << resistance.to_json unless resistance.empty?
  end
end

to_field 'retreat_cost_ssm' do |record, accumulator, _context|
  record.xpath('./retreat_cost').each do |node|
    accumulator << node.text.strip
  end
end

to_field 'converted_retreat_cost_isi' do |record, accumulator, _context|
  record.xpath('./converted_retreat_cost').each do |node|
    accumulator << node.text.strip.to_i
  end
end

to_field 'number_ssi', extract_xpath('./number')

to_field 'artist_ssi', extract_xpath('./artist')

to_field 'rarity_ssi', extract_xpath('./rarity')

to_field 'flavor_text_ssi', extract_xpath('./flavor_text')

to_field 'national_pokedex_numbers_ssm' do |record, accumulator, _context|
  record.xpath('./national_pokedex_numbers').each do |node|
    accumulator << node.text.strip
  end
end

to_field 'legalities_ssi' do |record, accumulator, _context|
  legalities_node = record.at_xpath('./legalities')

  if legalities_node
    # Create a hash from all child elements
    legalities = {}

    # Iterate through all child elements of the legalities node
    legalities_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      legalities[child.name] = child.text.strip
    end

    # Store the entire hash as a single JSON string
    accumulator << legalities.to_json unless legalities.empty?
  end
end

to_field 'images_ssi' do |record, accumulator, _context|
  images_node = record.at_xpath('./images')

  if images_node
    images = {}

    # Process all child elements dynamically
    images_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      images[child.name] = child.text.strip
    end

    accumulator << images.to_json unless images.empty?
  end
end

to_field 'tcgplayer_ssi' do |record, accumulator, _context|
  tcgplayer_node = record.at_xpath('./tcgplayer')

  if tcgplayer_node
    tcgplayer = {}

    # Process all child elements dynamically
    tcgplayer_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      tcgplayer[child.name] = child.text.strip
    end

    accumulator << tcgplayer.to_json unless tcgplayer.empty?
  end
end

to_field 'cardmarket_ssi' do |record, accumulator, _context|
  cardmarket_node = record.at_xpath('./cardmarket')

  if cardmarket_node
    cardmarket = {}

    # Process all child elements dynamically
    cardmarket_node.element_children.each do |child|
      # Use the child element's name as key and its text as value
      cardmarket[child.name] = child.text.strip
    end

    accumulator << cardmarket.to_json unless cardmarket.empty?
  end
end

# =============================
# Each component child document
# <c> <c01> <c12>
# =============================

to_field 'components' do |record, accumulator, context|
  child_components = record.xpath('c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12')
  component_indexer = Traject::Indexer::NokogiriIndexer.new.tap do |i|
    i.settings do
      provide :parent, context
      provide :root, context.settings[:root]
      provide :counter, context.settings[:counter]
      provide :component_traject_config, context.settings[:component_traject_config]
      provide :component_identifier_format, context.settings[:component_identifier_format]
    end

    i.load_config_file(context.settings[:component_traject_config])
  end

  child_components.each do |child_component|
    output = component_indexer.map_record(child_component)
    accumulator << output if output.keys.any?
  end
end
