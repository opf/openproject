module Lograge
  class SilentLogger < SimpleDelegator
    def initialize(logger)
      super
    end

    %i(debug info warn error fatal unknown).each do |method_name|
      define_method(method_name) { |*_args| }
    end
  end
end
