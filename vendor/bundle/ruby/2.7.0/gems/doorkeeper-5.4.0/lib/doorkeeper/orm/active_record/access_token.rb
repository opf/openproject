# frozen_string_literal: true

require "doorkeeper/orm/active_record/mixins/access_token"

module Doorkeeper
  class AccessToken < ::ActiveRecord::Base
    include Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  end
end
