module ChiliProject
  module Liquid
    module LiquidExt
      module Context
        def self.included(base)
          base.send(:include, InstanceMethods)
        end

        module InstanceMethods
          def html_result(html)
            key = nil
            while key.nil? || html_results.has_key?(key)
              random = ActiveSupport::SecureRandom.hex(10)
              # This string must be passed untouched through Liquid and textile
              # It mustn't be changed in any way by any rendering stage.
              key = "!!html_results.#{random}!!"
            end
            html_results[key] = html
            key
          end

          def html_results
            registers[:html_results] ||= {}
          end
        end
      end
    end
  end
end