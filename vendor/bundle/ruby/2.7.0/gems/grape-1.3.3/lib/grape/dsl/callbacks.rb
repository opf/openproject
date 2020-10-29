# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    # Blocks can be executed before or after every API call, using `before`, `after`,
    # `before_validation` and `after_validation`.
    #
    # Before and after callbacks execute in the following order:
    #
    # 1. `before`
    # 2. `before_validation`
    # 3. _validations_
    # 4. `after_validation`
    # 5. _the API call_
    # 6. `after`
    #
    # Steps 4, 5 and 6 only happen if validation succeeds.
    module Callbacks
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        # Execute the given block before validation, coercion, or any endpoint
        # code is executed.
        def before(&block)
          namespace_stackable(:befores, block)
        end

        # Execute the given block after `before`, but prior to validation or
        # coercion.
        def before_validation(&block)
          namespace_stackable(:before_validations, block)
        end

        # Execute the given block after validations and coercions, but before
        # any endpoint code.
        def after_validation(&block)
          namespace_stackable(:after_validations, block)
        end

        # Execute the given block after the endpoint code has run.
        def after(&block)
          namespace_stackable(:afters, block)
        end

        # Allows you to specify a something that will always be executed after a call
        # API call. Unlike the `after` block, this code will run even on
        # unsuccesful requests.
        # @example
        #   class ExampleAPI < Grape::API
        #     before do
        #       ApiLogger.start
        #     end
        #     finally do
        #       ApiLogger.close
        #     end
        #   end
        #
        # This will make sure that the ApiLogger is opened and close around every
        # request
        # @param  ensured_block [Proc] The block to be executed after every api_call
        def finally(&block)
          namespace_stackable(:finallies, block)
        end
      end
    end
  end
end
