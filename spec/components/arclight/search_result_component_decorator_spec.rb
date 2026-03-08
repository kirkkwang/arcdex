# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::SearchResultComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Arclight::SearchResultComponentDecorator

      def document=(doc)
        @document = doc
      end

      def solr_document_path(id)
        "/catalog/#{id}"
      end

      def link_to(content, path)
        "<a href='#{path}'>#{content}</a>"
      end

      def image_tag(url, **options)
        attrs = options.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
        "<img src=\"#{url}\" #{attrs}>"
      end
    end
  end

  describe '#icon' do
    subject(:component) { stub_class.new.tap { |c| c.document = document } }

    let(:document) do
      double('document', # rubocop:disable RSpec/VerifiedDoubles
             icon_url: 'https://example.com/thumb.jpg',
             normalized_title: 'Charizard',
             id: 'abc123')
    end

    it 'renders a lazy-loaded image' do
      expect(component.icon).to include('loading="lazy"')
    end

    it 'uses icon_url as the image source' do
      expect(component.icon).to include('src="https://example.com/thumb.jpg"')
    end

    it 'uses normalized_title in the alt text' do
      expect(component.icon).to include('Charizard')
    end

    it 'links to the solr document path' do
      expect(component.icon).to include('/catalog/abc123')
    end
  end
end
