require 'representable'

module Roar
  # generic features can be included here and will be available in all format-specific representers.
  module Representer
    def self.included(base)
      super
      base.send(:include, Representable)
    end
  end
end
