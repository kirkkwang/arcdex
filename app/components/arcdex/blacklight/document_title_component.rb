# OVERRIDE Blacklight v8.9.0 to not render the title

module Arcdex
  module Blacklight
    class DocumentTitleComponent < ::Blacklight::DocumentTitleComponent; end
  end
end
