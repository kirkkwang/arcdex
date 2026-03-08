# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::BoosterPackComponent do
  let(:document) { SolrDocument.new('collection_ssim' => ['Base Set'], 'title_ssm' => ['Base Set']) }
  let(:field_config) { double('field_config', compact: false, truncate: false, label: 'Booster Pack') } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'booster_pack') } # rubocop:disable RSpec/VerifiedDoubles

  let(:helpers_double) { double('helpers', search_action_url: '/catalog') } # rubocop:disable RSpec/VerifiedDoubles
  let(:component) do
    described_class.new(field:).tap do |c|
      allow(c).to receive(:link_to) { |img, _url| "<a>#{img}</a>" }
      allow(c).to receive_messages(image_tag: '<img src="booster.png">', helpers: helpers_double)
    end
  end

  describe '#label' do
    it 'appends a colon to the field config label' do
      expect(component.label).to eq('Booster Pack:')
    end
  end

  describe '#booster_pack' do
    it 'wraps each value in a link with a booster image' do
      result = component.booster_pack('booster_packs_ssm', ['Booster 1'])
      expect(result).to include('<a>')
      expect(result).to include('<img')
    end
  end
end
