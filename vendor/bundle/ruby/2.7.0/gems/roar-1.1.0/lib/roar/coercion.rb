gem 'virtus'
require 'virtus'
require 'representable/coercion'

module Roar
  # Use the +:type+ option to specify the conversion type.
  # class ImmigrantSong
  #   include Roar::JSON
  #   include Roar::Coercion
  #
  #   property :composed_at, :type => DateTime, :default => "May 12th, 2012"
  # end
  module Coercion
    def self.included(base)
      base.class_eval do
        include Representable::Coercion
      end
    end
  end
end
