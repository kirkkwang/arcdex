# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Arclight::GroupComponent do
  describe '#limit' do
    it 'returns the configured group limit from the Arclight engine' do
      configured_limit = Arclight::Engine.config.catalog_controller_group_query_params[:'group.limit']
      component = described_class.allocate
      expect(component.limit).to eq(configured_limit)
    end
  end
end
