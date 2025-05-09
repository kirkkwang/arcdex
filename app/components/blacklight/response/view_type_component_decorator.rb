# OVERRIDE Blacklight v8.9.0 to swap the list and gallery icon order

module Blacklight
  module Response
    module ViewTypeComponentDecorator
      def views
        super.reverse
      end
    end
  end
end

Blacklight::Response::ViewTypeComponent.prepend(Blacklight::Response::ViewTypeComponentDecorator)
