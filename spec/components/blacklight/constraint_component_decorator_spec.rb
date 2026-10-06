# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::ConstraintComponentDecorator, type: :component do
  let(:exclude_class) { 'text-decoration-line-through' }
  let(:constraint_presenter) { Blacklight::ConstraintPresenter.new(facet_item_presenter: item_presenter, field_label: 'Rarity') }

  describe '#initialize' do
    context 'when the facet item presenter does not respond to classes' do
      let(:item_presenter) { instance_double(Blacklight::FacetItemPresenter) }

      it 'falls back to the default filter classes' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: constraint_presenter)
        expect(component.instance_variable_get(:@classes)).to eq(%w[filter mx-1])
      end
    end

    context 'when the facet item presenter returns a custom class' do
      let(:item_presenter) { instance_double(Arcdex::ExcludeFacetItemPresenter, classes: exclude_class) }

      it 'uses the presenter classes instead of the default' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: constraint_presenter)
        expect(component.instance_variable_get(:@classes)).to eq([exclude_class])
      end
    end

    context 'when given a clause presenter' do
      let(:clause_presenter) { instance_double(Blacklight::ClausePresenter) }

      it 'falls back to the default filter classes' do
        component = Blacklight::ConstraintComponent.new(facet_item_presenter: clause_presenter)
        expect(component.instance_variable_get(:@classes)).to eq(%w[filter mx-1])
      end
    end
  end
end
