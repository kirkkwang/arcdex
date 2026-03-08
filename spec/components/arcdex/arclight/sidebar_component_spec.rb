# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Arclight::SidebarComponent do
  let(:component) { described_class.allocate }

  describe '#collection_sidebar' do
    it 'returns nil to suppress the default sidebar sections' do
      expect(component.collection_sidebar).to be_nil
    end
  end

  describe '#collection_context' do
    it 'renders a CollectionContextComponent' do
      ctx_component = double('ctx_component') # rubocop:disable RSpec/VerifiedDoubles
      allow(Arcdex::CollectionContextComponent).to receive(:new).and_return(ctx_component)
      allow(component).to receive_messages(document: double('document'), document_presenter: double('presenter'), render: '<div></div>') # rubocop:disable RSpec/VerifiedDoubles
      component.collection_context
      expect(component).to have_received(:render).with(ctx_component)
    end
  end
end
