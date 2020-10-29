# frozen_string_literal: true

module Grape
  module Extensions
    module Hashie
      module Mash
        module ParamBuilder
          extend ::ActiveSupport::Concern
          included do
            namespace_inheritable(:build_params_with, Grape::Extensions::Hashie::Mash::ParamBuilder)
          end

          def params_builder
            Grape::Extensions::Hashie::Mash::ParamBuilder
          end

          def build_params
            params = ::Hashie::Mash.new(rack_params)
            params.deep_merge!(grape_routing_args) if env[Grape::Env::GRAPE_ROUTING_ARGS]
            params
          end
        end
      end
    end
  end
end
