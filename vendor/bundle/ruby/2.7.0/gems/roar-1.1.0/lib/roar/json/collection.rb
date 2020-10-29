require 'roar/json'

module Roar::JSON
  module Collection
    include Roar::JSON

    def self.included(base)
      base.send :include, Representable::Hash::Collection
    end
  end
end
