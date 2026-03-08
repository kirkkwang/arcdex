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
