module Arcdex
  class MiradorViewerComponent < ViewComponent::Base
    def initialize(id:, width: '100%', height: '700px', allow: 'fullscreen')
      @id = id
      @width = width
      @height = height
      @allow = allow
    end

    private

    attr_reader :id, :width, :height, :allow

    def viewer
      content_tag :iframe, nil,
                  src: helpers.mirador_viewer(id:, encode: false),
                  width:,
                  height:,
                  allow:
    end
  end
end
