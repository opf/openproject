# frozen_string_literal: true

module Grape
  module Extensions
    module Hash
      module ParamBuilder
        extend ::ActiveSupport::Concern

        included do
          namespace_inheritable(:build_params_with, Grape::Extensions::Hash::ParamBuilder)
        end

        def build_params
          params = Grape::Extensions::DeepMergeableHash[rack_params]
          params.deep_merge!(grape_routing_args) if env[Grape::Env::GRAPE_ROUTING_ARGS]
          post_process_params(params)
        end

        def post_process_params(params)
          Grape::Extensions::DeepSymbolizeHash.deep_symbolize_keys_in(params)
        end
      end
    end
  end
end
