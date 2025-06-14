# OVERRIDE Arclight v1.6.0 to remove masthead

module Arclight
  module HeaderComponentDecorator
    def masthead; end
  end
end

Arclight::HeaderComponent.prepend(Arclight::HeaderComponentDecorator)
