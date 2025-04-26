# frozen_string_literal: true

namespace :arcdex do
  desc 'Index an EAD document, use FILE=<path/to/ead.xml> and REPOSITORY_ID=<myid>'
  # We need :environment to have access to the Blacklight confg
  task index: :environment do
    raise 'Please specify your EAD document, ex. FILE=<path/to/ead.xml>' unless ENV['FILE']

    print "Loading #{ENV.fetch('FILE', nil)} into index...\n"
    solr_url = ENV.fetch('SOLR_URL', Blacklight.default_index.connection.base_uri)
    elapsed_time = Benchmark.realtime do
      `bundle exec traject -u #{solr_url} -i xml -c #{Rails.root}/lib/arclight/traject/arcdex_config.rb #{ENV.fetch('FILE', nil)}`
    end
    print "Indexed #{ENV.fetch('FILE', nil)} (in #{elapsed_time.round(3)} secs).\n"
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
