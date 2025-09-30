# OVERRIDE Arclight v2.0.0.alpha for a completely different implementation not using yamls.

module Arclight
  module RepositoriesControllerDecorator
    def index
      @repositories = Arclight::Repository.all.sort_by(&:final_set_release_date).reverse
    end

    def show
      @repository = Arclight::Repository.find(params[:id])
      @collections = @repository.documents.reverse
    end

    def iiif_collection
      presenter = Arcdex::IiifCollectionPresenter.new(
        series: Arclight::Repository.find(params[:id]),
        base_url: request.protocol + request.host_with_port + series_path
      )

      respond_to do |format|
        format.json { render json: presenter }
      end
    end
  end
end

Arclight::RepositoriesController.prepend(Arclight::RepositoriesControllerDecorator)
