# frozen_string_literal: true

module TestManagement
  module Milestones
    class UpdateContract < BaseContract
      validate :project_unchanged

      private

      def project_unchanged
        errors.add :project, :error_readonly if model.project_id_changed?
      end
    end
  end
end
