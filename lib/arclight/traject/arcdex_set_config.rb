require_relative 'json_reader'
require 'logger'
require 'debug'

settings do
  provide 'card_config', File.join(__dir__, 'arcdex_card_config.rb')
  provide 'reader_class_name', 'Arclight::Traject::JsonReader'
  provide 'solr_writer.commit_on_close', 'true'
  provide 'logger', Logger.new($stderr)
end

# ==================
# Basic field mapping
# ==================

# Set this as a collection-level record
to_field 'level_ssm', lambda { |_record, accumulator| accumulator << 'collection' }
to_field 'level_ssim', lambda { |_record, accumulator| accumulator << 'Set' }
to_field 'id', lambda { |record, accumulator| accumulator << record.first['set']['id'] }
to_field 'child_component_count_isi', lambda { |record, accumulator| accumulator << record.count }
to_field 'ead_ssi' do |record, accumulator|
 accumulator << record.first['set']['id']
end

# Set collection fields
to_field 'title_ssm', lambda { |record, accumulator| accumulator << record.first['set']['name'] }
to_field 'title_tesim', lambda { |record, accumulator| accumulator << record.first['set']['name'] }
to_field 'normalized_title_ssm', lambda { |record, accumulator| accumulator << record.first['set']['name'] }

to_field 'series_ssm', lambda { |record, accumulator| accumulator << record.first['set']['series'] if record.first['set']['series'] }
to_field 'series_ssim', lambda { |record, accumulator| accumulator << record.first['set']['series'] if record.first['set']['series'] }

to_field 'printed_total_isi', lambda { |record, accumulator| accumulator << record.first['set']['printedTotal'].to_i if record.first['set']['printedTotal'] }
to_field 'printed_total_ssim', lambda { |record, accumulator| accumulator << record.first['set']['printedTotal'] if record.first['set']['printedTotal'] }

to_field 'total_items_isi', lambda { |record, accumulator| accumulator << record.first['set']['total'].to_i if record.first['set']['total'] }
to_field 'total_items_ssim', lambda { |record, accumulator| accumulator << record.first['set']['total'] if record.first['set']['total'] }

to_field 'legalities_json_ssi' do |record, accumulator|
  if record.first['set']['legalities']
    accumulator << record.first['set']['legalities'].to_json
  end
end
to_field 'legalities_ssm' do |record, accumulator|
  if record.first['set']['legalities']
    record.first['set']['legalities'].each do |format, status|
      accumulator << "#{format}: #{status}"
    end
  end
end

to_field 'ptcgo_code_ssi', lambda { |record, accumulator| accumulator << record.first['set']['ptcgoCode'] if record.first['set']['ptcgoCode'] }
to_field 'ptcgo_code_ssim', lambda { |record, accumulator| accumulator << record.first['set']['ptcgoCode'] if record.first['set']['ptcgoCode'] }

to_field 'release_date_ssm' do |record, accumulator|
  if record.first['set']['releaseDate']
    # Convert from 1999/01/09 to 1999-01-09 format
    formatted_date = record.first['set']['releaseDate'].gsub('/', '-')
    accumulator << formatted_date
  end
end
to_field 'release_year_isi' do |_record, accumulator, context|
  context.output_hash['release_date_ssm'].each do |date|
    # Extract the year from the date string
    year = date.split('-').first.to_i
    accumulator << year if year > 0
  end
end
to_field 'release_date_sort' do |record, accumulator|
  if record.first['set']['releaseDate']
    # Keep the format YYYY/MM/DD which sorts correctly as strings
    # Append set ID to ensure the set is grouped together even in all results view
    accumulator << (record.first['set']['releaseDate'] + record.first['set']['id'])
  end
end

to_field 'updated_at_ssm' do |record, accumulator|
  accumulator << record.first['set']['updatedAt'] if record.first['set']['updatedAt']
end
to_field 'updated_at_sort' do |record, accumulator|
  if record.first['set']['updatedAt']
    # Convert from "2022/10/10 15:12:00" to "2022-10-10T15:12:00"
    formatted_datetime = record.first['set']['updatedAt'].gsub('/', '-').gsub(' ', 'T')
    accumulator << formatted_datetime
  end
end

to_field 'images_json_ssi' do |record, accumulator|
  if record.first['set']['images']
    accumulator << record.first['set']['images'].to_json
  end
end
to_field 'symbol_url_ssm' do |record, accumulator|
  if record.first['set']['images'] && record.first['set']['images']['symbol']
    accumulator << record.first['set']['images']['symbol']
  end
end
to_field 'symbol_url_html_ssm' do |record, accumulator|
  if record.first['set']['images'] && record.first['set']['images']['symbol']
    url = record.first['set']['images']['symbol']
    accumulator << "<img src=\"#{url}\" alt=\"Set symbol\" class=\"set-symbol\" />"
  end
end
to_field 'logo_url_ssm' do |record, accumulator|
  if record.first['set']['images'] && record.first['set']['images']['logo']
    accumulator << record.first['set']['images']['logo']
  end
end
to_field 'logo_url_html_ssm' do |record, accumulator|
  if record.first['set']['images'] && record.first['set']['images']['logo']
    url = record.first['set']['images']['logo']
    accumulator << "<img src=\"#{url}\" alt=\"Set logo\" class=\"set-logo\" />"
  end
end
to_field 'thumbnail_path_ssi' do |record, accumulator|
  if record.first['set']['images'] && record.first['set']['images']['logo']
    accumulator << record.first['set']['images']['logo']
  end
end

to_field 'tcg_player_price_updated_at_ssi' do |record, accumulator|
  if record.first['tcgplayer'] && record.first['tcgplayer']['updatedAt']
    formatted_date = record.first['tcgplayer']['updatedAt'].gsub('/', '-')
    accumulator << formatted_date
  end
end

to_field 'extent_ssm' do |record, accumulator|
  accumulator << "#{record.first['set']['total']} total cards"
  accumulator << "ID: #{record.first['set']['id']}"
  accumulator << "Release Date: #{record.first['set']['releaseDate'].gsub('/', '-')}"
end

# =============================
# Each component child document
# =============================

to_field 'components' do |records, accumulator, context|
  cards = records

  counter = Class.new do
    def increment
      @counter ||= 0
      @counter += 1
    end
  end.new

  card_indexer = Traject::Indexer.new.tap do |i|
    i.settings do
      provide :reader_class_name, 'Arclight::Traject::JsonReader'
      provide :parent, context
      provide :root, context
      provide :counter, counter
      provide :depth, 1
      provide :logger, context.settings[:logger]
      provide :card_config, context.settings[:card_config]
      provide :total_records_count, cards.size
      provide :complete_set_count, cards.first['set']['printedTotal']
    end

    i.load_config_file(context.settings[:card_config])
  end

  cards.each do |card|
    output = card_indexer.map_record(card)
    accumulator << output unless accumulator.include?(output)
  end
end
