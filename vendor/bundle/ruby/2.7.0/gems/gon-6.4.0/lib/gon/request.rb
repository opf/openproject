class Gon
  class Request
    attr_reader :env, :gon
    attr_accessor :id

    def initialize(environment)
      @env = environment
      @gon = {}
    end

    def clear
      @gon = {}
    end

  end
end
