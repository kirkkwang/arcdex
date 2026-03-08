# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Blacklight::Document::ThumbnailComponent do
  let(:document) do
    SolrDocument.new(
      'id' => 'base-4',
      'thumbnail_path_ssi' => 'https://example.com/thumb.png',
      'large_url_ssm' => ['https://example.com/large.png'],
      'title_ssm' => ['Charizard']
    )
  end

  let(:component) { described_class.allocate.tap { |c| c.instance_variable_set(:@document, document) } }

  describe '#thumbnail_image' do
    before do
      allow(component).to receive_messages(
        content_tag: nil,
        concat: nil,
        render: '<div class="zoom-overlay"></div>'
      )
      allow(component).to receive(:content_tag).and_yield
      allow(component).to receive(:image_tag).and_return('<img>')
    end

    it 'does not raise when called with document data' do
      expect { component.thumbnail_image }.not_to raise_error
    end

    it 'uses the document thumbnail_url as image source' do
      component.thumbnail_image
      expect(component).to have_received(:image_tag).with('https://example.com/thumb.png', hash_including(alt: 'thumbnail'))
    end
  end
end
