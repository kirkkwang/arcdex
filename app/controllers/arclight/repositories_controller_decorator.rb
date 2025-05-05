# OVERRIDE Arclight v2.0.0.alpha for a completely different implementation not using yamls.

module Arclight
  module RepositoriesControllerDecorator
    def index
      @repositories = Arclight::Repository.all.sort_by(&:final_set_release_date).reverse
    end

    def show
      @repository = Arclight::Repository.find(params[:id])
      @collections = @repository.documents
    end
  end
end

Arclight::RepositoriesController.prepend(Arclight::RepositoriesControllerDecorator)
