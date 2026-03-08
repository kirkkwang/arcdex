# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::ConstraintComponentDecorator, type: :component do
  let(:exclude_class) { 'text-decoration-line-through' }

  describe '#initialize' do
    context 'when the presenter returns a blank classes value' do
      let(:presenter) { instance_double(Blacklight::FacetItemPresenter, classes: '') }

      it 'falls back to the default filter class' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: presenter)
        expect(component.instance_variable_get(:@classes)).to eq('filter')
      end
    end

    context 'when the presenter returns a custom class' do
      let(:presenter) { instance_double(Blacklight::FacetItemPresenter, classes: exclude_class) }

      it 'uses the presenter classes instead of the default' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: presenter)
        expect(component.instance_variable_get(:@classes)).to eq(exclude_class)
      end
    end

    context 'when the presenter returns nil' do
      let(:presenter) { instance_double(Blacklight::FacetItemPresenter, classes: nil) }

      it 'falls back to the default filter class' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: presenter)
        expect(component.instance_variable_get(:@classes)).to eq('filter')
      end
    end
  end
end
