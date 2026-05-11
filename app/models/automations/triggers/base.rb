# frozen_string_literal: true

module Automations
  module Triggers
    class Base < ApplicationRecord
      self.table_name = "automation_triggers"

      belongs_to :automation, inverse_of: :triggers

      acts_as_list scope: :automation
    end
  end
end
