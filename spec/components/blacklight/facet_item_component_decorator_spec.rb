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

  # Blacklight 8.12.3+ calls label, hits, href, and selected? in Facets::ItemComponent#initialize.
  # facet_item_presenter uses dynamically-added decorator methods not defined on the base class.
  def build_facet_item_double(facet_config:, exclude_href:, selected: false, hits: nil, excluded: false)
    instance_double(Blacklight::FacetItemPresenter,
                    label: 'Rare',
                    hits: hits,
                    href: '/catalog',
                    selected?: selected,
                    excluded_facet_item?: excluded,
                    exclude_href: exclude_href,
                    facet_config: facet_config)
  end

  describe '#initialize' do
    let(:facet_item_presenter) do
      build_facet_item_double(facet_config: excludable_facet_config,
                              exclude_href: '/catalog?f[-rarity][]=Rare')
    end

    it 'sets exclude_href from the facet_item presenter' do
      component = Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter)
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
        rendered = render_inline(Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_css('a.exclude-facet-link')
      end

      it 'renders the exclude icon' do
        rendered = render_inline(Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_css('span.exclude-facet-icon')
      end
    end

    context 'when the facet is not excludable' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: non_excludable_facet_config,
                                exclude_href: '/catalog?f[-supertype][]=Pokemon')
      end

      it 'does not render the exclude icon' do
        rendered = render_inline(Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_no_css('span.exclude-facet-icon')
      end
    end
  end

  describe '#render_selected_facet_value' do
    before { allow(vc_test_controller).to receive(:blacklight_config).and_return(blacklight_config) }

    context 'when the facet item is an excluded facet item' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: excludable_facet_config,
                                exclude_href: '/catalog?f[-rarity][]=Rare',
                                selected: true,
                                excluded: true)
      end

      it 'adds the exclude class to the selected span' do
        rendered = render_inline(Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered).to have_css("span.selected.#{exclude_class}", count: 1)
      end
    end

    context 'when the facet item is an inclusively selected facet item' do
      let(:facet_item_presenter) do
        build_facet_item_double(facet_config: excludable_facet_config,
                                exclude_href: '/catalog?f[-rarity][]=Rare',
                                selected: true,
                                excluded: false)
      end

      it 'does not add the exclude class to the selected span' do
        rendered = render_inline(Blacklight::Facets::ItemComponent.new(facet_item: facet_item_presenter))
        expect(rendered.to_html).not_to include(exclude_class)
      end
    end
  end
end
