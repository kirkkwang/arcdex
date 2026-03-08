# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Icons::OnlineComponentDecorator do
  describe 'custom SVG icon' do
    subject(:svg) { Blacklight::Icons::OnlineComponent.svg }

    it 'overrides the default icon with a custom SVG' do
      expect(svg).to include('<svg')
    end

    it 'uses the custom brand fill colors' do
      expect(svg).to include('092c68')
    end
  end
end
