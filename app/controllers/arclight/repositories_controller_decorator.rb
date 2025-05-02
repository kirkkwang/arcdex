# OVERRIDE Arclight v2.0.0.alpha for a completely different implementation not using yamls.

module Arclight
  module RepositoriesControllerDecorator
    def index
      @repositories = @repositories.sort_by(&:final_set_release_date).reverse
    end

    def show
      @repository = @repositories.find { |repository| repository.name == params[:id] }
      @collections = @repository.documents
    end

    private

    def set_repositories
      search_service = Blacklight.repository_class.new(blacklight_config)
      documents = search_service.search(q: "series_ssim:*", fq: "level_ssm:\"collection\"", rows: 10_000).documents

      @repositories = documents.group_by(&:series).map { |name, documents| Arclight::Repository.new(name, documents) }
    end
  end
end

Arclight::RepositoriesController.prepend(Arclight::RepositoriesControllerDecorator)
Arclight::RepositoriesController.before_action :set_repositories, only: [ :index, :show ]
