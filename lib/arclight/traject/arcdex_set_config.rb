require_relative 'json_reader'
require_relative '../../arcdex/card_adapter_factory'
require 'logger'
require 'debug'

settings do
  provide 'card_config', File.join(__dir__, 'arcdex_card_config.rb')
  provide 'reader_class_name', 'Arclight::Traject::JsonReader'
  provide 'solr_writer.commit_on_close', 'true'
  provide 'logger', Logger.new($stderr)
end

factory = Arcdex::CardAdapterFactory

# ==================
# Basic field mapping
# ==================

# Set this as a collection-level record
to_field 'level_ssm', lambda { |_record, accumulator| accumulator << 'collection' }
to_field 'level_ssim', lambda { |_record, accumulator| accumulator << 'Set' }
to_field 'id', lambda { |record, accumulator| accumulator << factory.call(record).set_id }
to_field 'child_component_count_isi', lambda { |record, accumulator| accumulator << factory.call(record).child_component_count }
to_field 'ead_ssi', lambda { |record, accumulator| accumulator << factory.call(record).set_id }

to_field 'has_online_content_ssim', lambda { |record, accumulator| accumulator << factory.call(record).has_online_content? }

# Set collection fields
to_field 'title_ssm', lambda { |record, accumulator| accumulator << factory.call(record).set_name }
to_field 'title_tesim', lambda { |record, accumulator| accumulator << factory.call(record).set_name }
to_field 'normalized_title_ssm', lambda { |record, accumulator| accumulator << factory.call(record).set_name }

to_field 'series_ssm', lambda { |record, accumulator| accumulator << factory.call(record).series }
to_field 'series_ssim', lambda { |record, accumulator| accumulator << factory.call(record).series }

to_field 'printed_total_isi', lambda { |record, accumulator| accumulator << factory.call(record).printed_total&.to_i }
to_field 'printed_total_ssim', lambda { |record, accumulator| accumulator << factory.call(record).printed_total }

to_field 'total_items_isi', lambda { |record, accumulator| accumulator << factory.call(record).total&.to_i }
to_field 'total_items_ssim', lambda { |record, accumulator| accumulator << factory.call(record).total }

to_field 'legalities_json_ssi', lambda { |record, accumulator| accumulator << factory.call(record).legalities&.to_json }
to_field 'legalities_ssm' do |record, accumulator|
  factory.call(record).legalities&.each do |format, status|
    accumulator << "#{format}: #{status}"
  end
end

to_field 'ptcgo_code_ssi', lambda { |record, accumulator| accumulator << factory.call(record).ptcgo_code }
to_field 'ptcgo_code_ssim', lambda { |record, accumulator| accumulator << factory.call(record).ptcgo_code }

# Convert from 1999/01/09 to 1999-01-09 format
to_field 'release_date_ssm', lambda { |record, accumulator| accumulator << factory.call(record).release_date }
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
  accumulator << (factory.call(record).release_date + factory.call(record).set_id)
end

to_field 'updated_at_ssm', lambda { |record, accumulator| accumulator << factory.call(record).updated_at }
to_field 'updated_at_sort' do |record, accumulator|
  if factory.call(record).updated_at
    # Convert from "2022/10/10 15:12:00" to "2022-10-10T15:12:00"
    formatted_datetime = factory.call(record).updated_at&.gsub('/', '-').gsub(' ', 'T')
    accumulator << formatted_datetime
  end
end

to_field 'images_json_ssi', lambda { |record, accumulator| accumulator << factory.call(record).images_json }
to_field 'symbol_url_ssm', lambda { |record, accumulator| accumulator << factory.call(record).symbol_url }
to_field 'symbol_url_html_ssm' do |record, accumulator|
  if factory.call(record).images_json && factory.call(record).symbol_url
    url = factory.call(record).symbol_url
    accumulator << "<img src=\"#{url}\" alt=\"Set symbol\" class=\"set-symbol\" />"
  end
end
to_field 'logo_url_ssm' do |record, accumulator|
  if factory.call(record).images_json && factory.call(record).logo_url
    accumulator << factory.call(record).logo_url
  end
end
to_field 'logo_url_html_ssm' do |record, accumulator|
  if factory.call(record).images_json && factory.call(record).logo_url
    url = factory.call(record).logo_url
    accumulator << "<img src=\"#{url}\" alt=\"Set logo\" class=\"set-logo\" />"
  end
end
to_field 'thumbnail_path_ssi' do |record, accumulator|
  if factory.call(record).images_json && factory.call(record).logo_url
    accumulator << factory.call(record).logo_url
  end
end

to_field 'tcg_player_price_updated_at_ssi' do |record, accumulator|
  if factory.call(record).tcgplayer && factory.call(record).tcgplayer_updated_at
    formatted_date = factory.call(record).tcgplayer_updated_at
    accumulator << formatted_date
  end
end

to_field 'extent_ssm' do |record, accumulator|
  accumulator << "#{factory.call(record).total} total cards"
  accumulator << "ID: #{factory.call(record).set_id}"
  accumulator << "Release Date: #{factory.call(record).release_date}"
end

# =============================
# Each component child document
# =============================

to_field 'components' do |records, accumulator, context|
  cards = if records.is_a?(Array) # pokemontcg.io
            records
  else # tcgdex.dev
            records.fetch('cards', [])
  end

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
      provide :complete_set_count, factory.call(records).total
      provide :release_date, factory.call(records).release_date
      provide :set_id, factory.call(records).set_id
      provide :has_online_content, factory.call(records).has_online_content?
    end

    i.load_config_file(context.settings[:card_config])
  end

  cards.each do |card|
    output = card_indexer.map_record(card)
    accumulator << output unless accumulator.include?(output)
  end
end
