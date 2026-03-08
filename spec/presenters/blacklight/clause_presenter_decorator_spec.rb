# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::ClausePresenterDecorator do
  subject(:presenter) do
    Blacklight::ClausePresenter.new('q_1', { query: 'pikachu' }, field_config, view_context, search_state)
  end

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }
  let(:field_config) do
    blacklight_config.add_search_field 'all_fields', label: 'All Fields'
    blacklight_config.search_fields['all_fields']
  end
  # view_context uses dynamically-added Blacklight helper methods not on ActionView::Base
  let(:view_context) { double('view_context', search_state: search_state) } # rubocop:disable RSpec/VerifiedDoubles


  describe '#classes' do
    it 'returns nil' do
      expect(presenter.classes).to be_nil
    end
  end
end
