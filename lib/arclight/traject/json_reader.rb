module Arclight
  module Traject
    class JsonReader
      attr_reader :input_stream, :settings, :logger

      def initialize(input_stream, settings)
        @input_stream = input_stream
        @settings = settings
        @logger = settings['logger']
      end

      def each
        json_content = JSON.parse(input_stream.read)
        cards = json_content['data'] || json_content # TCGDex uses info from the entire JSON

        yield cards
      end
    end
  end
end
