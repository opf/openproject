module SWD
  class Response
    attr_accessor :locations, :location, :raw

    def initialize(hash)
      @locations = hash[:locations]
      @location = @locations.first
      @raw = hash
    end
  end
end