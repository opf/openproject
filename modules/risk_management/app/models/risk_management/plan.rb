# frozen_string_literal: true

module RiskManagement
  class Plan < ApplicationRecord
    self.table_name = "risk_management_plans"

    belongs_to :project
    belongs_to :author, class_name: "User"
    belongs_to :updated_by, class_name: "User"

    validates :project, :author, :updated_by, presence: true
  end
end
