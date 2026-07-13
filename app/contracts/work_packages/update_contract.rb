# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  class UpdateContract < BaseContract
    include UnchangedProject

    class << self
      def update_allowed?(user:, work_package:)
        allowed_in_work_package?(user, work_package, :edit_work_packages) ||
          allowed_in_project?(user, work_package, :assign_versions) ||
          allowed_in_project?(user, work_package, :change_work_package_status) ||
          allowed_in_project?(user, work_package, :manage_subtasks) ||
          allowed_in_project?(user, work_package, :move_work_packages)
      end

      def update_parent_allowed?(user:, work_package:)
        allowed_in_project?(user, work_package, :manage_subtasks)
      end

      def add_comments_allowed?(user:, work_package:)
        allowed_in_work_package?(user, work_package, :add_work_package_comments)
      end

      private

      def allowed_in_project?(user, work_package, permission)
        user.allowed_in_project?(permission, work_package.project)
      end

      def allowed_in_work_package?(user, work_package, permission)
        user.allowed_in_work_package?(permission, work_package)
      end
    end

    attribute :lock_version,
              permission: %i[edit_work_packages change_work_package_status assign_versions manage_subtasks
                             move_work_packages] do
      if model.lock_version.nil? || model.lock_version_changed?
        errors.add :base, :error_conflict
      end
    end

    validate :user_allowed_to_access

    validate :user_allowed_to_edit

    validate :user_allowed_to_move_from_source_project

    validate :can_move_to_milestone

    default_attribute_permission :edit_work_packages
    attribute_permission :project_id, :move_work_packages

    private

    def user_allowed_to_edit
      with_unchanged_project_id do
        next if self.class.update_allowed?(user:, work_package: model)
        next if allowed_journal_addition?

        errors.add :base, :error_unauthorized
      end
    end

    # When moving a work package to a different project, require
    # :move_work_packages in the source project (the project the work
    # package currently belongs to). The per-attribute permission check
    # (reduce_by_writable_permissions) evaluates :move_work_packages
    # against the target project; this validation covers the source side.
    def user_allowed_to_move_from_source_project
      return unless model.project_id_changed?

      with_unchanged_project_id do
        unless user.allowed_in_project?(:move_work_packages, model.project)
          errors.add :project_id, :error_readonly
        end
      end
    end

    def user_allowed_to_access
      unless ::WorkPackage.visible(@user).exists?(model.id)
        errors.add :base, :error_not_found
      end
    end

    def allowed_journal_addition?
      model.changes.empty? && model.journal_notes && self.class.add_comments_allowed?(user:, work_package: model)
    end

    def can_move_to_milestone
      return unless model.type_id_changed? && model.milestone?

      if model.children.any?
        errors.add :type, :cannot_be_milestone_due_to_children
      end
    end
  end
end
