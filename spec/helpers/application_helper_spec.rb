# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#additional_locale_routing_scopes' do
    it 'returns an array with two routing scopes' do
      expect(helper.additional_locale_routing_scopes.length).to eq(2)
    end
  end
end
