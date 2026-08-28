# frozen_string_literal: true

module RiskManagement
  class RiskCategory < ApplicationRecord
    self.table_name = "risk_categories"

    belongs_to :color, optional: true

    acts_as_list

    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :active, -> { where(active: true) }
  end
end
