# OVERRIDE Arclight v2.0.0.alpha to completely go a different direction with this object.
#   We pass in the series name and set solr documents instead of yaml loading.

module Arclight
  module RepositoryDecorator
    extend ActiveSupport::Concern

    class_methods do
      def all
        @repositories ||=
          begin
          search_service = Blacklight.repository_class.new(CatalogController.blacklight_config)
          documents = search_service.search(q: 'series_ssim:*', fq: 'level_ssm:"collection"', rows: 10_000).documents

          documents.group_by(&:series).map { |name, documents| new(name, documents) }
          end
      end

      def find(id)
        all.find { |repository| repository.name == id }
      end
    end

    attr_reader :name, :documents

    def initialize(name, documents)
      @name = name

      @documents = documents.sort_by(&:release_date)
    end

    def final_set_release_date
      documents.last.release_date
    end

    def slug
      name
    end

    def attributes
      []
    end

    # Override Arclight v2.0.0.alpha because we don't use request types and it was throwing an error.
    def request_types
      []
    end
  end
end

Arclight::Repository.prepend(Arclight::RepositoryDecorator)
