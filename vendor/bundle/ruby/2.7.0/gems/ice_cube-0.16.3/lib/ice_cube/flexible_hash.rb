require 'delegate'

module IceCube

  # Find keys by symbol or string without symbolizing user input
  # Due to the serialization format of ice_cube, this limited implementation
  # is entirely sufficient

  class FlexibleHash < SimpleDelegator

    def [](key)
      key = _match_key(key)
      super
    end

    def fetch(key)
      key = _match_key(key)
      super
    end

    def delete(key)
      key = _match_key(key)
      super
    end

    private

    def _match_key(key)
      return key if __getobj__.has_key? key
      if Symbol == key.class
        __getobj__.keys.detect { |k| return k if k == key.to_s }
      elsif String == key.class
        __getobj__.keys.detect { |k| return k if k.to_s == key }
      end
      key
    end

  end

end
