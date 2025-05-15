# frozen_string_literal: true

# OVERRIDE Blacklight v8.9.0 to to fix auto complete popup not being easily dismissible

module Arcdex
  module Blacklight
    class SearchBarComponent < ::Blacklight::SearchBarComponent; end
  end
end
