module Arcdex
  class Hashids
    SALT = 'arcdex'
    MIN_LENGTH = 8

    def self.encode(id)
      ::Hashids.new(SALT, MIN_LENGTH).encode(id)
    end

    def self.decode(hashid)
      return if hashid.include?('-') # SolrDocument ids have '-' so we skip those

      ::Hashids.new(SALT, MIN_LENGTH).decode(hashid).first
    end
  end
end
