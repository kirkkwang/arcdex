# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::GroupComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Arclight::GroupComponentDecorator

      attr_writer :mock_helpers

      def document
        @document
      end

      def document=(doc)
        @document = doc
      end

      def helpers
        @mock_helpers
      end

      def search_catalog_path(params)
        params
      end
    end
  end

  describe '#search_within_collection_url' do
    subject(:component) do
      stub_class.new.tap do |c|
        c.document = document
        c.mock_helpers = mock_helpers
      end
    end

    let(:collection_name) { 'Base Set' }
    let(:document) { double('document', collection_name: collection_name) } # rubocop:disable RSpec/VerifiedDoubles
    let(:mock_helpers) { double('helpers', search_without_group: {}) } # rubocop:disable RSpec/VerifiedDoubles

    it 'uses the set facet key with the collection name' do
      result = component.search_within_collection_url
      expect(result).to include(f: { set: [collection_name] })
    end
  end
end
