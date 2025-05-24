# OVERRIDE Arclight v2.0.0.alpha to customize what's displayed

module Arcdex
  class CollectionInfoComponent < ::Arclight::CollectionInfoComponent
    delegate :complete_set_count, :master_set_count, to: :collection
  end
end
