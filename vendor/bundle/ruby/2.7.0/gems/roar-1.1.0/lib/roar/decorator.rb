require 'roar/representer'
require 'representable/decorator'

class Roar::Decorator < Representable::Decorator
  module HypermediaConsumer
    def links=(arr)
      super
      represented.instance_variable_set :@links, self.links
    end
  end
end