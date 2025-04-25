module Arclight
  module Traject
    class JsonReader
      attr_reader :input_stream, :settings

      def initialize(input_stream, settings)
        @input_stream = input_stream
        @settings = settings
      end

      def each
        json_content = JSON.parse(input_stream.read)
        cards = json_content["data"]

        # If we're processing for collections (sets)
        if settings["processing_collections"]
          # Extract the set information from the first card
          # (since all cards in a file belong to the same set)
          if cards.any?
            set_info = cards.first["set"]
            # Add a type field to distinguish this as a collection
            set_info["type"] = "collection"
            yield set_info
          end
        else
          # Regular card processing - each card as a component
          cards.each do |card|
            # Add a type field to distinguish this as a component
            card["type"] = "component"
            yield card
          end
        end
      end
    end
  end
end
