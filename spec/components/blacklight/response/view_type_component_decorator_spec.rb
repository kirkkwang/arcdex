# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Response::ViewTypeComponentDecorator do
  let(:stub_class) do
    Class.new do
      prepend Blacklight::Response::ViewTypeComponentDecorator

      def views = %i[list gallery]
    end
  end

  describe '#views' do
    subject(:component) { stub_class.new }

    it 'reverses the default view order' do
      expect(component.views).to eq(%i[gallery list])
    end
  end
end
