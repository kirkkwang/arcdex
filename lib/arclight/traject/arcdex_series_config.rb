require_relative 'json_reader'
require 'logger'
require 'debug'

settings do
  provide 'set_config', File.join(__dir__, 'arcdex_set_config.rb')
  provide 'reader_class_name', 'Arclight::Traject::JsonReader'
  provide 'solr_writer.commit_on_close', 'true'
  provide 'logger', Logger.new($stderr)
  provide 'series', 'true'
end

to_field 'level_ssm', lambda { |_records, accumulator| accumulator << 'series' }

to_field 'id', lambda { |records, accumulator| accumulator << records.first['set']['series'].downcase.strip.gsub(/^_+|_+$/, '') }

to_field 'title_ssm', lambda { |records, accumulator| accumulator << records.first['set']['series'] }
to_field 'title_tesim', lambda { |records, accumulator| accumulator << records.first['set']['series'] }

to_field 'normalized_title_ssm' do |_records, accumulator, context|
  accumulator << context.output_hash['title_ssm']&.first
end

# =============================
# Each component child document
# =============================

to_field 'components' do |records, accumulator, context|
  set = records
  next unless set

  counter = Class.new do
    def increment
      @counter ||= 0
      @counter += 1
    end
  end.new

  set_indexer = Traject::Indexer.new.tap do |i|
    i.settings do
      provide :reader_class_name, 'Arclight::Traject::JsonReader'
      provide :parent, context
      provide :root, context
      provide :counter, counter
      provide :depth, 1
      provide :logger, context.settings[:logger]
      provide :set_config, context.settings[:set_config]
      provide :total_records_count, set.size
    end

    i.load_config_file(context.settings[:set_config])
  end

  set.each do |child_component|
    output = set_indexer.map_record(child_component)
    accumulator << output unless accumulator.include?(output)
  end

  components = accumulator.map do |set|
    set.delete('components').first
  end

  accumulator.uniq!

  accumulator.first['components'] = components
end
