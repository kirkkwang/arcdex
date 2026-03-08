# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::SearchNavbarComponentDecorator do
  # Test the decorator module in isolation using a stub class,
  # since ViewComponent raises an error if controller/helpers are
  # accessed outside of the render pipeline.
  let(:stub_class) do
    Class.new do
      prepend Blacklight::SearchNavbarComponentDecorator

      attr_writer :action_name

      def render? = true
      def action_name = @action_name
    end
  end

  describe '#render?' do
    subject(:component) { stub_class.new }

    context 'when on the advanced_search action' do
      before { component.action_name = 'advanced_search' }

      it 'returns false' do
        expect(component.render?).to be false
      end
    end

    context 'when on any other action' do
      before { component.action_name = 'index' }

      it 'delegates to super' do
        expect(component.render?).to be true
      end
    end
  end
end
