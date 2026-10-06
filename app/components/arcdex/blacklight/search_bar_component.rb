# frozen_string_literal: true

# OVERRIDE Blacklight v9.2.1 to fix auto complete popup not being easily dismissible

module Arcdex
  module Blacklight
    class SearchBarComponent < ::Blacklight::SearchBarComponent; end
  end
end
