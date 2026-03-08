# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController do
  let(:mock_docs) { [instance_double(SolrDocument, id: 'base-4')] }
  let(:mock_response) do
    instance_double(
      Blacklight::Solr::Response,
      documents: mock_docs,
      current_page: 1,
      total_pages: 2,
      next_page: 2
    )
  end
  let(:mock_repository) do
    instance_double(Blacklight::Solr::Repository, search: mock_response)
  end
  let(:mock_search_service) do
    instance_double(Blacklight::SearchService,
                    search_results: mock_response,
                    repository: mock_repository)
  end

  before do
    allow_any_instance_of(described_class).to receive(:search_service) # rubocop:disable RSpec/AnyInstance
      .and_return(mock_search_service)
  end

  describe 'Arcdex::InfiniteScrollable#index' do
    context 'with infinite_scroll JSON request' do
      before do
        allow_any_instance_of(described_class).to receive(:render_to_string).and_return('<div>docs</div>') # rubocop:disable RSpec/AnyInstance
        get :index, params: { infinite_scroll: true }, format: :json
      end

      it 'returns JSON with documents_html and pagination' do
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to have_key('documents_html')
        expect(body).to have_key('pagination')
      end
    end
  end

  describe 'Arcdex::IiifManifestable#fetch_documents (user bookmark branch)' do
    let(:mock_user) { instance_double(User, ordered_bookmark_ids: ['base-4']) }
    let(:mock_manifest_presenter) { instance_double(Arcdex::IiifManifestPresenter) }

    before do
      allow(Arcdex::Hashids).to receive(:decode).and_return(42)
      allow(User).to receive(:find_by).with(id: 42).and_return(mock_user)
      allow(Arcdex::IiifManifestPresenter).to receive(:new).and_return(mock_manifest_presenter)
      allow(mock_manifest_presenter).to receive(:to_json).and_return('{}')
      get :iiif_manifest, params: { id: 'encoded-user-id' }, format: :json
    end

    it 'loads bookmark documents and returns JSON' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Arcdex::IiifManifestable#iiif_manifest' do
    let(:mock_manifest_presenter) { instance_double(Arcdex::IiifManifestPresenter) }

    before do
      allow(Arcdex::IiifManifestPresenter).to receive(:new).and_return(mock_manifest_presenter)
      allow(mock_manifest_presenter).to receive(:to_json).and_return('{}')
      get :iiif_manifest, params: { id: 'base-set' }, format: :json
    end

    it 'returns a JSON response' do
      expect(response).to have_http_status(:ok)
    end
  end
end
