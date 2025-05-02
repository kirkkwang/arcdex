# OVERRIDE Arclight v2.0.0.alpha to completely go a different direction with this object.
#   We pass in the series name and set solr documents instead of yaml loading.

module Arclight
  module RepositoryDecorator
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
  end
end

Arclight::Repository.prepend(Arclight::RepositoryDecorator)
