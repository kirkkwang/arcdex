# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::BreadcrumbsHierarchyComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Arclight::BreadcrumbsHierarchyComponentDecorator

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

      def link_to(text, path)
        "<a href='#{path}'>#{text}</a>"
      end
    end
  end

  describe '#repository' do
    subject(:component) do
      stub_class.new.tap do |c|
        c.document = document
        c.mock_helpers = mock_helpers
      end
    end

    let(:series) { 'Base Set' }
    let(:document) { double('document', series: series) } # rubocop:disable RSpec/VerifiedDoubles
    let(:mock_helpers) do
      double('helpers', repository_path: '/repositories/Base+Set') # rubocop:disable RSpec/VerifiedDoubles
    end

    it 'passes document.series to helpers.repository_path' do
      component.repository
      expect(mock_helpers).to have_received(:repository_path).with(series)
    end

    it 'links to the repository path' do
      expect(component.repository).to include('/repositories/Base+Set')
    end
  end
end
