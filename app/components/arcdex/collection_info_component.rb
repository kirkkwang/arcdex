# OVERRIDE Arclight v2.0.0.alpha to customize what's displayed

module Arcdex
  class CollectionInfoComponent < ::Arclight::CollectionInfoComponent
    delegate :complete_set_count, :master_set_count, :tcg_player_price_updated_at, to: :collection
  end
end
