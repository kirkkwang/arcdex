# frozen_string_literal: true

require_relative '../arcdex/bulbapedia/client'
require_relative '../arcdex/bulbapedia/expansion_parser'
require_relative '../arcdex/bulbapedia/card_parser'

namespace :arcdex do
  EXPANSIONS_CATEGORY = 'Category:Pokémon TCG Pocket expansions'

  desc 'Pull all Pokémon TCG Pocket expansions from Bulbapedia'
  task pull_bulbapedia: :environment do
    titles = bulbapedia_expansion_titles
    puts "🎴 Found #{titles.size} Pocket expansions on Bulbapedia"
    titles.each { |title| pull_bulbapedia_expansion(title) }
  end

  desc 'Pull a single Pocket expansion from Bulbapedia (SET=B3a or SET="Paradox Drive")'
  task pull_bulbapedia_set: :environment do
    set = ENV.fetch('SET', nil)
    raise 'SET required (e.g., SET=B3a or SET="Paradox Drive")' if set.nil?

    pull_bulbapedia_expansion(resolve_bulbapedia_title(set))
  end

  def bulbapedia_client # rubocop:disable Rake/MethodDefinitionInTask
    @bulbapedia_client ||= Arcdex::Bulbapedia::Client.new
  end

  def bulbapedia_expansion_titles # rubocop:disable Rake/MethodDefinitionInTask
    bulbapedia_client.category_members(EXPANSIONS_CATEGORY)
                     .select { |t| t.end_with?('(TCG Pocket)') }
  end

  # Accept a set name ("Paradox Drive") or a set code ("B3a").
  def resolve_bulbapedia_title(set) # rubocop:disable Rake/MethodDefinitionInTask
    return "#{set} (TCG Pocket)" if set.include?(' ')

    titles = bulbapedia_expansion_titles
    contents = bulbapedia_client.pages_wikitext(titles)
    match = contents.find do |_title, wikitext|
      wikitext && Arcdex::Bulbapedia::ExpansionParser.parse(wikitext)['id']&.casecmp?(set)
    end
    raise "Could not resolve set #{set.inspect} to a Bulbapedia expansion" if match.nil?

    match.first
  end

  def pull_bulbapedia_expansion(title) # rubocop:disable Rake/MethodDefinitionInTask
    puts "\n📦 #{title}"
    expansion_wikitext = bulbapedia_client.page_wikitext(title)
    raise "No wikitext for #{title}" if expansion_wikitext.nil?

    expansion = Arcdex::Bulbapedia::ExpansionParser.parse(expansion_wikitext)
    set_code = expansion['id']
    set_name = expansion['name']
    rows = expansion['rows']
    puts "   #{set_code} — #{set_name}: #{rows.size} cards listed (#{expansion['printed_total']}/#{expansion['total']})"

    card_titles = rows.map { |r| card_title(set_name, r) }
    contents = bulbapedia_client.pages_wikitext(card_titles)

    cards = rows.filter_map do |row|
      wikitext = contents[card_title(set_name, row)]
      next puts("   ⚠️  missing page for #{row['name']} #{row['number']}") if wikitext.nil?

      Arcdex::Bulbapedia::CardParser.parse(wikitext, set_code: set_code, set_name: set_name, row: row)
    end
    resolve_boosters!(cards, set_name)

    set_json = {
      '_source' => 'bulbapedia',
      'id' => set_code,
      'name' => set_name,
      'release_date' => expansion['release_date'],
      'printed_total' => expansion['printed_total'],
      'total' => expansion['total'],
      'cards' => cards
    }
    write_pocket_json(set_code, set_json, cards.size)
  end

  def card_title(set_name, row) # rubocop:disable Rake/MethodDefinitionInTask
    "#{row['name']} (#{set_name} #{row['local_number']})"
  end

  # Expand each card's pack into the set's booster roster: the distinct named
  # packs (e.g. Mewtwo/Charizard/Pikachu), or the set itself for a single-booster
  # set.  A card marked "Any" belongs to every booster; a specific pack stays as
  # is; a card with no pack (e.g. promos) gets none.
  def resolve_boosters!(cards, set_name) # rubocop:disable Rake/MethodDefinitionInTask
    roster = cards.flat_map { |c| c['boosters'] }.uniq - ['Any']
    roster = [set_name] if roster.empty?
    cards.each do |card|
      card['boosters'] = roster if card['boosters'].include?('Any')
    end
  end

  def write_pocket_json(set_code, set_json, card_count) # rubocop:disable Rake/MethodDefinitionInTask
    if card_count.zero?
      puts "   ⚠️  0 cards parsed for #{set_code}; skipping save to preserve existing data."
      return
    end

    output_path = Rails.root.join('data', 'pocket', "#{set_code}.json")
    output_path.dirname.mkpath

    if output_path.exist?
      existing = JSON.parse(output_path.read)['cards']&.size || 0
      if card_count < existing
        puts "   ⚠️  new data has fewer cards (#{card_count}) than existing (#{existing}); skipping save."
        return
      end
    end

    output_path.write(JSON.pretty_generate(set_json))
    puts "   💾 saved #{card_count} cards → #{output_path.relative_path_from(Rails.root)}"
  end
end
