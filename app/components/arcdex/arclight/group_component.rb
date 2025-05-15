# OVERRIDE Arclight v2.0.0.alpha to increase group limit size

module Arcdex
  module Arclight
    class GroupComponent < ::Arclight::GroupComponent
      def limit
        ::Arclight::Engine.config.catalog_controller_group_query_params[:'group.limit']
      end
    end
  end
end
