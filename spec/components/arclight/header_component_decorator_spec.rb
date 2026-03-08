# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::HeaderComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Arclight::HeaderComponentDecorator

      def masthead = 'original masthead html'
    end
  end

  describe '#masthead' do
    subject(:component) { stub_class.new }

    it 'returns nil, suppressing the masthead' do
      expect(component.masthead).to be_nil
    end
  end
end
