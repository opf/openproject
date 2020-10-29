require "disposable/twin/property/struct"

class Disposable::Twin
  module Struct
    def self.included(includer)
      warn "[Disposable] The Struct module is deprecated, please use Property::Struct."
      includer.send(:include, Property::Struct)
    end
  end
end
