require 'dry/container/item'

module Dry
  class Container
    class Item
      # Callable class to returns a item call
      #
      # @api public
      #
      class Callable < Item
        # Returns the result of item call or item
        #
        # @return [Mixed]
        def call
          callable? ? item.call : item
        end
      end
    end
  end
end
