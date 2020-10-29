# frozen_string_literal: true

module Grape
  module Extensions
    module ActiveSupport
      module HashWithIndifferentAccess
        module ParamBuilder
          extend ::ActiveSupport::Concern

          included do
            namespace_inheritable(:build_params_with, Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder)
          end

          def params_builder
            Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
          end

          def build_params
            params = ::ActiveSupport::HashWithIndifferentAccess.new(rack_params)
            params.deep_merge!(grape_routing_args) if env[Grape::Env::GRAPE_ROUTING_ARGS]
            params
          end
        end
      end
    end
  end
end
