# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::BoosterPackComponent, type: :component do
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

  describe '#image_tag (private)' do
    # Must use render_inline so the component has a proper ActionView context for super
    let(:field_config_with_field) { double('field_config', compact: false, truncate: false, label: 'Booster Pack', field: 'booster_packs_ssm') } # rubocop:disable RSpec/VerifiedDoubles
    let(:field_with_values) { double('field', document:, field_config: field_config_with_field, key: 'booster_pack', values: ['Booster 1']) } # rubocop:disable RSpec/VerifiedDoubles
    let(:resolver) { double('resolver') } # rubocop:disable RSpec/VerifiedDoubles
    let(:assets) { double('assets', resolver:) } # rubocop:disable RSpec/VerifiedDoubles
    let(:renderable) do
      described_class.new(field: field_with_values).tap do |c|
        allow(c).to receive(:helpers).and_return(helpers_double)
      end
    end

    before { allow(Rails.application).to receive(:assets).and_return(assets) }

    context 'when the asset is not in the pipeline (resolver returns nil)' do
      before { allow(resolver).to receive(:resolve).and_return(nil) }

      it 'checks the asset resolver' do
        render_inline(renderable)
        expect(resolver).to have_received(:resolve)
      end
    end

    context 'when the asset is found in the pipeline' do
      before { allow(resolver).to receive(:resolve).and_return('/assets/boosters/base-set-booster.png') }

      it 'checks the asset resolver' do
        render_inline(renderable)
        expect(resolver).to have_received(:resolve).at_least(:once)
      end
    end
  end
end
