# frozen_string_literal: true

module TestManagement
  # Who can be assigned to a test run / a case in a run: active users that are
  # members of the project (any role). Unlike work package assignees this does
  # not require the :work_package_assigned permission or the work package module.
  module Assignees
    module_function

    def scope(project)
      ::User.active.where(id: ::Member.where(project_id: project.id).select(:user_id))
    end

    def possible?(project, user_id)
      user_id.present? && scope(project).exists?(id: user_id)
    end
  end
end
