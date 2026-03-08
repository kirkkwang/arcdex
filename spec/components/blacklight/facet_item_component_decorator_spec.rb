# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::FacetItemComponentDecorator, type: :component do
  let(:exclude_class) { 'text-decoration-line-through' }

  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.index.constraints_component_exclude_styling = exclude_class
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
    config.add_facet_field 'supertype', field: 'supertype_ssm', excludable: false
    config
  end

  let(:excludable_facet_config) { blacklight_config.facet_fields['rarity'] }
  let(:non_excludable_facet_config) { blacklight_config.facet_fields['supertype'] }

  # Blacklight 8.12.3+ calls label, hits, href, and selected? in FacetItemComponent#initialize.
  # facet_item_presenter uses dynamically-added decorator methods not defined on the base class.
  def build_facet_item_double(facet_config:, exclude_href:, selected: false, hits: nil)
    instance_double(Blacklight::FacetItemPresenter,
                    label: 'Rare',
                    hits: hits,
                    href: '/catalog',
                    selected?: selected,
                    exclude_href: exclude_href,
                    facet_config: facet_config)
  end

  describe '#initialize' do
    let(:facet_item_presenter) do
      build_facet_item_double(facet_config: excludable_facet_config,
                              exclude_href: '/catalog?f[-rarity][]=Rare')
    end

    it 'sets exclude_href from the facet_item presenter' do
      component = Blacklight::FacetItemComponent.new(facet_item: facet_item_presenter)
      expect(component.exclude_href).to eq('/catalog?f[-rarity][]=Rare')
    end
  end

  describe '#exclude_facet_link' do
    context 'when the facet is excludable' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: excludable_facet_config,
                                exclude_href: '/catalog?f[-rarity][]=Rare')
      end

      it 'renders a link with the exclude-facet-link class' do
        rendered = render_inline(Blacklight::FacetItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_css('a.exclude-facet-link')
      end

      it 'renders the exclude icon' do
        rendered = render_inline(Blacklight::FacetItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_css('span.exclude-facet-icon')
      end
    end

    context 'when the facet is not excludable' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: non_excludable_facet_config,
                                exclude_href: '/catalog?f[-supertype][]=Pokemon')
      end

      it 'does not render the exclude icon' do
        rendered = render_inline(Blacklight::FacetItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_no_css('span.exclude-facet-icon')
      end
    end
  end

  describe '#render_selected_facet_value' do
    context 'when the facet item is selected with no hits' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: excludable_facet_config,
                                exclude_href: '/catalog?f[-rarity][]=Rare',
                                selected: true,
                                hits: nil)
      end

      # helpers in ViewComponent uses dynamically composed view context;
      # allow_any_instance_of is the only practical way to stub it across render_inline
      before do
        view_config = double('view_config', constraints_component_exclude_styling: exclude_class) # rubocop:disable RSpec/VerifiedDoubles
        bl_config = double('bl_config', view_config: view_config) # rubocop:disable RSpec/VerifiedDoubles
        allow_any_instance_of(Blacklight::FacetItemComponent).to receive(:helpers) do |_instance| # rubocop:disable RSpec/AnyInstance
          double('helpers', blacklight_config: bl_config, t: 'Remove') # rubocop:disable RSpec/VerifiedDoubles
        end
      end

      it 'adds the exclude class to the selected span' do
        rendered = render_inline(Blacklight::FacetItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered.to_html).to include(exclude_class)
      end
    end
  end
end
