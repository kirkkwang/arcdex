# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookmarksController do
  let(:mock_user) do
    instance_double(User,
                    id: 1,
                    update_bookmark_order!: true)
  end

  before do
    # verify_user is a Blacklight before_action that requires Warden/Devise;
    # stub it out so controller specs can run without a full auth stack
    allow_any_instance_of(described_class).to receive(:verify_user) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
      .to receive(:token_or_current_or_guest_user)
      .and_return(mock_user)
  end

  describe '#index' do
    let(:mock_docs) { [instance_double(SolrDocument, id: 'doc-1')] }
    let(:mock_response) do
      instance_double(
        Blacklight::Solr::Response,
        documents: mock_docs,
        current_page: 1,
        total_pages: 1,
        next_page: nil
      )
    end
    let(:mock_bookmarks) do
      instance_double(ActiveRecord::Associations::CollectionProxy, pluck: ['doc-1'], count: 1)
    end

    before do
      allow_any_instance_of(described_class).to receive(:search_service) # rubocop:disable RSpec/AnyInstance
        .and_return(instance_double(Blacklight::SearchService, search_results: mock_response))
      allow(mock_user).to receive_messages(bookmarks: mock_bookmarks, bookmark_order: ['doc-1'])
      get :index
    end

    it 'returns 200 ok' do
      expect(response).to have_http_status(:ok)
    end

    it 'assigns bookmarks' do
      expect(assigns(:bookmarks)).to eq(mock_bookmarks)
    end
  end

  describe '#update_order' do
    context 'when the order update succeeds' do
      before do
        allow(ActionCable.server).to receive(:broadcast)
        post :update_order, params: { new_order: 'id1,id2,id3' }
      end

      it 'returns 200 ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'broadcasts the new order via ActionCable' do
        expect(ActionCable.server).to have_received(:broadcast)
      end
    end

    context 'when the order update fails' do
      before do
        allow(mock_user).to receive(:update_bookmark_order!).and_return(false)
        post :update_order, params: { new_order: 'id1,id2,id3' }
      end

      it 'returns 422 unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
