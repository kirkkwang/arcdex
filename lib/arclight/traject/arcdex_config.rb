require 'logger'
require 'traject'
require 'traject/nokogiri_reader'
require 'traject_plus'
require 'traject_plus/macros'
require 'active_model/conversion' ## Needed for Arclight::Repository
require 'active_support/core_ext/array/wrap'

extend TrajectPlus::Macros

settings do
  provide 'component_traject_config', File.join(__dir__, 'arcdex_component_config.rb')
  provide 'solr_writer.commit_on_close', 'true'
  provide 'repository', ENV.fetch('REPOSITORY_ID', nil)
  provide 'logger', Logger.new($stderr)
end

each_record do |_record, context|
  next unless settings['repository']

  context.clipboard[:repository] = Arclight::Repository.find_by(
    slug: settings['repository']
  ).name
end

# ==================
# Top level document
#
# NOTE: All fields should be stored in Solr
# ==================

to_field 'level_ssm' do |_record, accumulator|
  accumulator << 'series'
end

to_field 'id' do |record, accumulator|
  accumulator << record.at_xpath('/series/series_id')&.text
end

to_field 'title_ssm', extract_xpath('/series/set/name')
to_field 'title_tesim', extract_xpath('/series/set/name')
to_field 'ead_ssi', extract_xpath('/series/series_id')

to_field 'normalized_title_ssm' do |_record, accumulator, context|
  accumulator << context.output_hash['title_ssm']&.first
end

# =============================
# Each component child document
# <c> <c01> <c12>
# =============================

to_field 'components' do |record, accumulator, context|
  child_components = record.xpath("/series/set/card/c|#{('/series/set/card/c01'..'/series/set/card/c12').to_a.join('|')}")
  next unless child_components.any?

  counter = Class.new do
    def increment
      @counter ||= 0
      @counter += 1
    end
  end.new

  component_indexer = Traject::Indexer::NokogiriIndexer.new.tap do |i|
    i.settings do
      provide :parent, context
      provide :root, context
      provide :counter, counter
      provide :depth, 1
      provide :logger, context.settings[:logger]
      provide :component_traject_config, context.settings[:component_traject_config]
    end

    i.load_config_file(context.settings[:component_traject_config])
  end

  child_components.each do |child_component|
    output = component_indexer.map_record(child_component)
    accumulator << output if output.keys.any?
  end
end
