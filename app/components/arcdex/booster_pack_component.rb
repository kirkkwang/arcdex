module Arcdex
  class BoosterPackComponent < Arcdex::UpperMetadataLayoutComponent
    def label
      "#{field.field_config.label}:"
    end

    def booster_pack(field, values)
      values.map! do |value|
        link_to(
          image_tag(booster_image_url(value),
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

    # R2 keys are populated by scripts/harvest-set-images.sh and keyed by pack
    # only, so strip the "Set - " prefix the booster label carries.
    def booster_image_url(value)
      pack = value.delete_prefix("#{document.collection_name} - ")
      "https://images.arcdex.dev/#{set_code}-booster-#{pack.parameterize}.webp"
    end

    # a1-026 -> a1, promo-a-001 -> promo-a
    def set_code
      id = document.id.to_s
      id[/\A(.+)-\d+\z/, 1] || id
    end

    def image_tag(source, options = {})
      if Rails.application.assets.resolver.resolve(source).nil?
        super(source, skip_pipeline: true, **options)
      else
        super(source, **options)
      end
    end
  end
end
