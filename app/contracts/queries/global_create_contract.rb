# frozen_string_literal: true

require 'queries/create_contract'

module Queries
  class GlobalCreateContract < CreateContract
    validate :validate_project_present

    private

    def validate_project_present
      errors.add :project_id, :blank if model.project_id.blank?
    end
  end
end
