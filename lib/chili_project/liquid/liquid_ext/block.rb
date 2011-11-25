module ChiliProject
  module Liquid
    module LiquidExt
      module Block
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.class_eval do
            alias_method_chain :render_all, :cleaned_whitespace
          end
        end

        module InstanceMethods
          def render_all_with_cleaned_whitespace(list, context)
            # Remove the leading newline in a block's content
            list[0].sub!(/\A\r?\n/, "") if list[0].is_a?(String)
            render_all_without_cleaned_whitespace(list, context)
          end
        end
      end
    end
  end
end