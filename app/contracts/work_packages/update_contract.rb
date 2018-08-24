#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'work_packages/base_contract'

module WorkPackages
  class UpdateContract < BaseContract
    attribute :lock_version do
      if model.lock_version.nil? || model.lock_version_changed?
        errors.add :base, :error_conflict
      end
    end

    validate :user_allowed_to_access

    validate :user_allowed_to_edit

    validate :user_allowed_to_move

    private

    def user_allowed_to_edit
      with_unchanged_project_id do
        next if @can.allowed?(model, :edit)
        next user_allowed_to_change_parent if @can.allowed?(model, :manage_subtasks)
        next if allowed_journal_addition?

        errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_change_parent
      allowed_changes = { parent_id: true, lock_version: true }

      model.changed.each do |key|
        next if allowed_changes[key.to_sym]
        return errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_access
      unless ::WorkPackage.visible(@user).exists?(model.id)
        errors.add :base, :error_not_found
      end
    end

    def user_allowed_to_move
      if model.project_id_changed? &&
         !@can.allowed?(model, :move)

        errors.add :project, :error_unauthorized
      end
    end

    def with_unchanged_project_id
      if model.project_id_changed?
        current_project_id = model.project_id

        model.project_id = model.project_id_was

        yield

        model.project_id = current_project_id
      else
        yield
      end
    end

    def allowed_journal_addition?
      model.changes.empty? && model.journal_notes && can.allowed?(model, :comment)
    end
  end
end
