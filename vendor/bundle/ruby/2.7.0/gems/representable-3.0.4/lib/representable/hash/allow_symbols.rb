module Representable
  module Hash
    module AllowSymbols
    private
      def filter_wrap_for(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end

      def update_properties_from(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end
    end

    class Conversion
      # DISCUSS: we could think about mixin in IndifferentAccess here (either hashie or ActiveSupport).
      # or decorating the hash.
      def self.stringify_keys(hash)
        hash = hash.dup

        hash.keys.each do |k|
          hash[k.to_s] = hash.delete(k)
        end
        hash
      end
    end
  end
end