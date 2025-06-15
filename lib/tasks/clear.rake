namespace :arcdex do
  desc 'Clear all data from Solr'
  task clear: :environment do
    repository = Blacklight.repository_class.new(CatalogController.blacklight_config)
    repository.connection.delete_by_query('*:*')
    repository.connection.commit
  end
end
