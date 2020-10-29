# frozen_string_literal: true

module Grape
  module Extensions
    class DeepMergeableHash < ::Hash
      def deep_merge!(other_hash)
        other_hash.each_pair do |current_key, other_value|
          this_value = self[current_key]

          self[current_key] = if this_value.is_a?(::Hash) && other_value.is_a?(::Hash)
                                this_value.deep_merge(other_value)
                              else
                                other_value
                              end
        end

        self
      end
    end
  end
end
