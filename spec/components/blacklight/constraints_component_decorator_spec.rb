# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::ConstraintsComponentDecorator, type: :component do
  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.index.constraints_component_exclude_styling = 'text-decoration-line-through'
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
    config
  end

  let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

  # helpers in ViewComponent uses dynamically composed view context;
  # Blacklight helper methods are not defined on ActionView::Base
  let(:mock_helpers) do
    double('helpers', # rubocop:disable RSpec/VerifiedDoubles
           blacklight_config: blacklight_config,
           search_action_path: '/catalog',
           search_state: search_state)
  end

  describe '#facet_item_presenters' do
    context 'with no facet filters' do
      let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }
      let(:component) { Blacklight::ConstraintsComponent.new(search_state: search_state) }

      before { allow(component).to receive(:helpers).and_return(mock_helpers) }

      it 'yields no presenters' do
        presenters = component.send(:facet_item_presenters).to_a
        expect(presenters).to be_empty
      end
    end

    context 'with a regular (non-exclude) facet filter' do
      let(:search_state) { Blacklight::SearchState.new({ f: { 'rarity' => ['Rare'] } }, blacklight_config) }
      let(:component) { Blacklight::ConstraintsComponent.new(search_state: search_state) }

      before { allow(component).to receive(:helpers).and_return(mock_helpers) }

      it 'yields a regular facet item presenter' do
        presenters = component.send(:facet_item_presenters).to_a
        expect(presenters).not_to be_empty
      end
    end

    context 'with only exclude facet filters' do
      let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }
      let(:component) { Blacklight::ConstraintsComponent.new(search_state: search_state) }

      before { allow(component).to receive(:helpers).and_return(mock_helpers) }

      it 'yields an ExcludeFacetItemPresenter' do
        presenters = component.send(:facet_item_presenters).to_a
        expect(presenters.length).to eq(1)
        expect(presenters.first).to be_a(Arcdex::ExcludeFacetItemPresenter)
      end
    end

    context 'with multiple excluded values for one facet' do
      let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare', 'Common'] } }, blacklight_config) }
      let(:component) { Blacklight::ConstraintsComponent.new(search_state: search_state) }

      before { allow(component).to receive(:helpers).and_return(mock_helpers) }

      it 'yields one ExcludeFacetItemPresenter per excluded value' do
        presenters = component.send(:facet_item_presenters).to_a
        expect(presenters.length).to eq(2)
        expect(presenters).to all(be_a(Arcdex::ExcludeFacetItemPresenter))
      end
    end

    context 'with an inclusive (Array) facet filter' do
      let(:search_state) { Blacklight::SearchState.new({ f_inclusive: { 'rarity' => ['Rare', 'Common'] } }, blacklight_config) }
      let(:component) { Blacklight::ConstraintsComponent.new(search_state: search_state) }

      before { allow(component).to receive(:helpers).and_return(mock_helpers) }

      it 'yields an inclusive facet item presenter' do
        presenters = component.send(:facet_item_presenters).to_a
        expect(presenters).not_to be_empty
      end
    end
  end
end
