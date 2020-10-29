# frozen_string_literal: true

module Prawn
  module Markup
    module HashMerger
      def self.deep(hash, other)
        hash.merge(other) do |_key, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            deep(this_val, other_val)
          else
            other_val
          end
        end
      end

      def self.enhance(options, key, hash)
        options[key] = hash.merge(options[key])
      end
    end
  end
end
