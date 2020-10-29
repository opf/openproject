# frozen_string_literal: true

require "doorkeeper/orm/active_record/redirect_uri_validator"
require "doorkeeper/orm/active_record/mixins/application"

module Doorkeeper
  class Application < ::ActiveRecord::Base
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  end
end
