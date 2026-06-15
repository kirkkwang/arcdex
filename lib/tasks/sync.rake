# frozen_string_literal: true

require_relative '../arcdex/bulbapedia/client'
require_relative '../arcdex/bulbapedia/expansion_parser'

namespace :arcdex do
  desc 'Incremental: pull + index new or grown sets from both sources (daily cron). FORCE=a1,b3a or FORCE=all to refetch regardless.'
  task sync: :environment do
    changed = sync_source('pokemontcg.io') { sync_main_tcg } +
              sync_source('Bulbapedia') { sync_pocket }
    if changed.empty?
      puts '✅ No new or grown sets.'
    else
      puts "✅ Synced #{changed.size} set(s): #{changed.join(', ')}"
    end
  end

  # Isolate the two sources so one's index-fetch outage doesn't suppress the other.
  def sync_source(name) # rubocop:disable Rake/MethodDefinitionInTask
    yield
  rescue StandardError => e
    warn "⚠️  #{name} sync aborted: #{e.message}"
    []
  end

  def sync_main_tcg # rubocop:disable Rake/MethodDefinitionInTask
    puts '🌎 Checking pokemontcg.io sets…'
    sets = fetch_and_parse_with_retry("#{POKEMON_TCG_IO_BASE_URL}/sets")['data']
    sets.filter_map do |set|
      path = Rails.root.join('data', "#{set['id']}.json")
      next unless needs_pull?(set['id'], path, set['total'])

      puts "  ⬇️  #{set['id']} (#{set['name']})"
      pull_set('id' => set['id'], 'total' => set['total'], 'name' => set['name'])
      index_set(path)
      set['id']
    rescue StandardError => e
      warn "  ⚠️  #{set['id']} failed: #{e.message}"
      nil
    end
  end

  # Bulbapedia has no totals index, so each expansion page is fetched to read its
  # code and total before deciding whether to (re)pull.
  def sync_pocket # rubocop:disable Rake/MethodDefinitionInTask
    puts '🎴 Checking Bulbapedia Pocket expansions…'
    bulbapedia_expansion_titles.filter_map do |title|
      wikitext = bulbapedia_client.page_wikitext(title)
      next if wikitext.nil?

      expansion = Arcdex::Bulbapedia::ExpansionParser.parse(wikitext)
      code = expansion['id']
      next warn("  ⚠️  #{title}: could not parse set code, skipping") if code.nil?

      path = Rails.root.join('data', 'pocket', "#{code}.json")
      next unless needs_pull?(code, path, expansion['total'])

      puts "  ⬇️  #{code} (#{expansion['name']})"
      pull_bulbapedia_expansion(title)
      index_set(path)
      code
    rescue StandardError => e
      warn "  ⚠️  #{title} failed: #{e.message}"
      nil
    end
  end

  # Both sources persist their upstream `total`, so an unchanged set compares
  # equal and is skipped; a missing file or a higher upstream total triggers a pull.
  def needs_pull?(id, path, upstream_total) # rubocop:disable Rake/MethodDefinitionInTask
    return true if forced?(id)
    return true unless path.exist?

    stored = JSON.parse(path.read)
    have = stored['total'] || stored['totalCount'] || stored['cards']&.size || 0
    upstream_total.to_i > have.to_i
  end

  # FORCE=all refetches everything; FORCE=a1,b3a refetches a specific set list.
  def forced?(id) # rubocop:disable Rake/MethodDefinitionInTask
    force = ENV['FORCE'].to_s.strip
    return false if force.empty?
    return true if force.casecmp?('all')

    force.split(',').map { |s| s.strip.downcase }.include?(id.to_s.downcase)
  end

  # Raise on a failed index so the set is reported as failed, not silently
  # counted as synced (the data file is already written either way).
  def index_set(path) # rubocop:disable Rake/MethodDefinitionInTask
    raise "indexing failed for #{path}" unless system("RUBYOPT=-W0 FILE=#{path} rails arcdex:index")
  end
end
