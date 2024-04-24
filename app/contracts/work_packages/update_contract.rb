#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

    attribute :lock_version,
              permission: %i[edit_work_packages change_work_package_status assign_versions manage_subtasks move_work_packages] do
      if model.lock_version.nil? || model.lock_version_changed?
        errors.add :base, :error_conflict
      end
    end

    validate :user_allowed_to_access

    validate :user_allowed_to_edit

    validate :can_move_to_milestone

    validate :user_allowed_to_change_parent

    default_attribute_permission :edit_work_packages
    attribute_permission :project_id, :move_work_packages

    private

    def user_allowed_to_edit
      with_unchanged_project_id do
        next if @can.allowed?(model, :edit) ||
                @can.allowed?(model, :assign_version) ||
                @can.allowed?(model, :change_status) ||
                @can.allowed?(model, :manage_subtasks) ||
                @can.allowed?(model, :move)
        next if allowed_journal_addition?

        errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_access
      unless ::WorkPackage.visible(@user).exists?(model.id)
        errors.add :base, :error_not_found
      end
    end

    def allowed_journal_addition?
      model.changes.empty? && model.journal_notes && can.allowed?(model, :comment)
    end

    def can_move_to_milestone
      return unless model.type_id_changed? && model.milestone?

      if model.children.any?
        errors.add :type, :cannot_be_milestone_due_to_children
      end
    end

    def user_allowed_to_change_parent
      return if model.parent_id.nil? || model.parent.nil?
      return unless model.parent_id_changed?

      unless model.parent.visible?
        errors.add :parent_id, :error_unauthorized
      end
    end
  end
end
