module Arcdex
  module IiifManifestable
    extend ActiveSupport::Concern

    included do
      before_action :fetch_documents, only: :iiif_manifest
    end

    def iiif_manifest
      presenter = Arcdex::IiifManifestPresenter.new(
        base_url: request.protocol + request.host_with_port + search_catalog_path,
        start_id: params[:id],
        fields: blacklight_config.component_indexed_terms_fields,
        documents: @documents,
        set_id: @set_id
      )

      respond_to do |format|
        format.json { render json: presenter }
      end
    end

    private

    def fetch_documents
      @set_id = params[:id].split('-').first
      @documents = search_service.repository.search(
        { q: "parent_ids_ssim:\"#{@set_id}\"", sort: 'sort_ssi asc', rows: 1_000 }
      ).documents
    end
  end
end
