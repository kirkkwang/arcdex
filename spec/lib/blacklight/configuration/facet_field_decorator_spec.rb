# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Configuration::FacetFieldDecorator do
  let(:blacklight_config) { Blacklight::Configuration.new }

  describe '#normalize!' do
    context 'when excludable: true is configured' do
      subject(:facet_field) do
        blacklight_config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
        blacklight_config.facet_fields['rarity']
      end

      it 'sets excludable to true' do
        expect(facet_field.excludable).to be true
      end
    end

    context 'when excludable is not configured' do
      subject(:facet_field) do
        blacklight_config.add_facet_field 'rarity', field: 'rarity_ssm'
        blacklight_config.facet_fields['rarity']
      end

      it 'does not set excludable' do
        expect(facet_field.excludable).to be_falsey
      end
    end

    context 'when excludable: false is configured' do
      subject(:facet_field) do
        blacklight_config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: false
        blacklight_config.facet_fields['rarity']
      end

      it 'does not set excludable to true' do
        expect(facet_field.excludable).not_to be true
      end
    end
  end
end
