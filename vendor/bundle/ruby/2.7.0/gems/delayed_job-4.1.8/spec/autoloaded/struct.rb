# Make sure this file does not get required manually
module Autoloaded
  Struct = ::Struct.new(nil)
  class Struct
    def perform; end
  end
end
