module Arcdex
  class BoosterPackComponent < Arcdex::UpperMetadataLayoutComponent
    def label
      "#{field.field_config.label}:"
    end

    def booster_pack(field, values)
      values.map! do |value|
        link_to(
          image_tag("boosters/#{[document.collection_name, value].join('-').parameterize}.png",
            alt: value,
            title: value,
            style: 'max-height: 1.75rem;'),
          helpers.search_action_url(
            f: { booster_packs: [value] },
            search_field: 'booster_packs')
        )
      end

      values.join.html_safe # rubocop:disable Rails/OutputSafety
    end

    private

    def image_tag(source, options = {})
      if Rails.application.assets.resolver.resolve(source).nil?
        super(source, skip_pipeline: true, **options)
      else
        super(source, **options)
      end
    end
  end
end
