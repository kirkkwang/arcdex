# frozen_string_literal: true

namespace :arcdex do
  desc "Index Pokemon TCG data (use FILE=path/to/file.json to index a single file)"
  task index: :environment do
    require "traject"

    solr_url = Blacklight.connection_config[:url]

    # Determine which files to process
    files_to_process = if ENV["FILE"].present?
                         [ ENV["FILE"] ]
    else
                         Dir.glob(Rails.root.join("data", "*.json"))
    end

    # Process each file
    files_to_process.each do |file|
      puts "Processing #{file}..."
      start_time = Time.now

      begin
        # Create fresh indexers for each file

        # Set indexer
        set_indexer = Traject::Indexer.new.tap do |i|
          i.load_config_file(Rails.root.join("lib", "arclight", "traject", "arcdex_set_config.rb"))
          i.settings do
            provide "solr.url", solr_url
            provide "reader_class_name", "Arclight::Traject::JsonReader"
            provide "processing_collections", true
          end
        end

        # Card indexer
        card_indexer = Traject::Indexer.new.tap do |i|
          i.load_config_file(Rails.root.join("lib", "arclight", "traject", "arcdex_card_config.rb"))
          i.settings do
            provide "solr.url", solr_url
            provide "reader_class_name", "Arclight::Traject::JsonReader"
            provide "processing_collections", false
          end
        end

        # First index the set as a collection
        puts "Indexing set information..."
        File.open(file) do |f|
          set_indexer.process(f)
        end

        # Then index all cards as components
        puts "Indexing card information..."
        File.open(file) do |f|
          card_indexer.process(f)
        end

        puts "Indexed #{file} (in #{(Time.now - start_time).round(3)} secs)"
      rescue => e
        puts "Error indexing #{file}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end

    puts "Indexing complete!"
  end

  desc "Delete all documents from the Solr index"
  task clear: :environment do
    solr_url = Blacklight.connection_config[:url]

    puts "Clearing all documents from Solr index..."
    solr = RSolr.connect(url: solr_url)
    solr.delete_by_query "*:*"
    solr.commit
    puts "Index cleared successfully!"
  end
end
