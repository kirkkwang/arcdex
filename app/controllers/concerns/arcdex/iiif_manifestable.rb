module Arcdex
  module IiifManifestable
    extend ActiveSupport::Concern

    included do
      before_action :fetch_documents, only: :iiif_manifest
    end

    def iiif_manifest
      presenter = Arcdex::IiifManifestPresenter.new(
        base_url: request.protocol + request.host_with_port + search_catalog_path,
        start_id: @start_id,
        fields: blacklight_config.component_indexed_terms_fields,
        documents: @documents,
        set_id: @set_id,
        from_bookmarks: @from_bookmarks
      )

      respond_to do |format|
        format.json { render json: presenter }
      end
    end

    private

    def fetch_documents
      user_id = Arcdex::Hashids.decode(params[:id])

      if user_id.present?
        user = User.find_by(id: user_id)
        ids =   user.ordered_bookmark_ids
        query = { q: '*:*', fq: "id:(#{ids.join(' OR ')})", rows: ids.size }

        @set_id = params[:id]
        @start_id = nil
        @documents = search_service.repository.search(query).documents
        @documents.sort_by! { |doc| ids.index(doc.id) || Float::INFINITY }
        @from_bookmarks = true
      else
        @set_id = params[:id].split('-').first
        @start_id = params[:id]
        @documents = search_service.repository.search(
          { q: "parent_ids_ssim:\"#{@set_id}\"", sort: 'sort_ssi asc', rows: 1_000 }
        ).documents
      end
    end
  end
end
