# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::CollectionContextComponent, type: :component do
  let(:collection) { instance_double(SolrDocument, normalized_title: 'Base Set', downloads: []) }
  let(:presenter) { double('presenter', document: double('doc', collection: collection)) } # rubocop:disable RSpec/VerifiedDoubles
  let(:download_component) { Arclight::DocumentDownloadComponent }
  let(:component) { described_class.new(presenter:, download_component:) }

  describe '#collection_info' do
    it 'renders a CollectionInfoComponent for the collection' do
      allow(component).to receive(:render)
      component.collection_info
      expect(component).to have_received(:render).with(an_instance_of(Arcdex::CollectionInfoComponent))
    end
  end
end
