# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::ConstraintLayoutComponentDecorator, type: :component do
  let(:exclude_class) { 'text-decoration-line-through' }

  # helpers in ViewComponent uses dynamically composed view context;
  # allow_any_instance_of is the only practical way to stub it across render_inline
  let(:mock_helpers) do
    view_config = double('view_config', constraints_component_exclude_styling: exclude_class) # rubocop:disable RSpec/VerifiedDoubles
    bl_config = double('bl_config', view_config: view_config) # rubocop:disable RSpec/VerifiedDoubles
    double('helpers', blacklight_config: bl_config) # rubocop:disable RSpec/VerifiedDoubles
  end

  before do
    allow_any_instance_of(Blacklight::ConstraintLayoutComponent) # rubocop:disable RSpec/AnyInstance
      .to receive(:helpers).and_return(mock_helpers)
  end

  describe '#remove_aria_label (via rendered output)' do
    context 'when the component has the exclude styling class and a label' do
      it 'uses the remove_excluded label_value translation' do
        rendered = render_inline(
          Blacklight::ConstraintLayoutComponent.new(
            value: 'Rare', label: 'Rarity', classes: exclude_class, remove_path: '/catalog'
          )
        )
        expected = I18n.t('blacklight.search.filters.remove_excluded.label_value',
                          label: 'Rarity', value: 'Rare')
        expect(rendered).to have_css('.visually-hidden', text: expected)
      end
    end

    context 'when the component has the exclude class but no label' do
      it 'uses the remove_excluded value-only translation' do
        rendered = render_inline(
          Blacklight::ConstraintLayoutComponent.new(
            value: 'Rare', classes: exclude_class, remove_path: '/catalog'
          )
        )
        expected = I18n.t('blacklight.search.filters.remove_excluded.value', value: 'Rare')
        expect(rendered).to have_css('.visually-hidden', text: expected)
      end
    end

    context 'when the component does not have the exclude class' do
      it 'uses the standard remove label_value translation' do
        rendered = render_inline(
          Blacklight::ConstraintLayoutComponent.new(
            value: 'Rare', label: 'Rarity', classes: 'filter', remove_path: '/catalog'
          )
        )
        expected = I18n.t('blacklight.search.filters.remove.label_value',
                          label: 'Rarity', value: 'Rare')
        expect(rendered).to have_css('.visually-hidden', text: expected)
      end

      it 'does not include the word "excluded"' do
        rendered = render_inline(
          Blacklight::ConstraintLayoutComponent.new(
            value: 'Rare', label: 'Rarity', classes: 'filter', remove_path: '/catalog'
          )
        )
        expect(rendered.to_html).not_to include('excluded')
      end
    end
  end
end
