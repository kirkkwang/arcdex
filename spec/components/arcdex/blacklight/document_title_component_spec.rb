# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Blacklight::DocumentTitleComponent do
  let(:document) { double('document', title: 'Charizard', id: 'base-4') } # rubocop:disable RSpec/VerifiedDoubles
  let(:component) { described_class.allocate.tap { |c| c.instance_variable_set(:@document, document) } }

  describe '#title' do
    before do
      allow(component).to receive(:solr_document_path).with(document, anchor: 'title').and_return('/catalog/base-4#title')
      allow(component).to receive(:link_to) { |label, path, **| "<a href='#{path}'>#{label}</a>" }
    end

    it 'links to the document path with the title anchor' do
      result = component.title
      expect(result).to include('/catalog/base-4#title')
      expect(result).to include('Charizard')
    end
  end
end
