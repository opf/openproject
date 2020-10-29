# frozen_string_literal: true

require "doorkeeper/orm/active_record/mixins/access_grant"

module Doorkeeper
  class AccessGrant < ::ActiveRecord::Base
    include Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
  end
end
