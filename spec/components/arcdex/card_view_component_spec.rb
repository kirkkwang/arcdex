# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::CardViewComponent do
  let(:document) do
    SolrDocument.new('id' => 'base-4', 'large_url_ssm' => ['https://example.com/large.png'], 'title_ssm' => ['Charizard'])
  end

  let(:field_config) { double('field_config', compact: false, truncate: false) } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'card_view') } # rubocop:disable RSpec/VerifiedDoubles

  let(:component) do
    described_class.new(field:).tap do |c|
      allow(c).to receive(:content_tag) { |_tag, _content, **attrs| "<img src='#{attrs[:src]}'>" }
    end
  end

  describe '#image' do
    it 'generates an img element using the document image_url' do
      result = component.image
      expect(result).to include('https://example.com/large.png')
    end
  end

  describe '#viewer' do
    it 'renders a MiradorViewerComponent' do
      allow(component).to receive(:render).and_return('<div class="mirador"></div>')
      component.viewer
      expect(component).to have_received(:render)
    end
  end
end
