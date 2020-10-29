# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    module API
      extend ActiveSupport::Concern

      include Grape::Middleware::Auth::DSL

      include Grape::DSL::Validations
      include Grape::DSL::Callbacks
      include Grape::DSL::Configuration
      include Grape::DSL::Helpers
      include Grape::DSL::Middleware
      include Grape::DSL::RequestResponse
      include Grape::DSL::Routing
    end
  end
end
