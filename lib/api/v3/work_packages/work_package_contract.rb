#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'reform'
require 'reform/form/active_model/model_validations'

module API
  module V3
    module WorkPackages
      class WorkPackageContract < Reform::Contract
        WRITEABLE_ATTRIBUTES = [
          'lock_version',
          'subject',
          'parent_id',
          'description',
          'status_id',
          'assigned_to_id',
          'responsible_id'
        ].freeze

        def initialize(object, user)
          super(object)

          @user = user
          @can = WorkPackagePolicy.new(user)
        end

        validate :user_allowed_to_access
        validate :user_allowed_to_edit
        validate :user_allowed_to_edit_parent
        validate :lock_version_valid
        validate :readonly_attributes_unchanged
        validate :assignee_visible
        validate :responsible_visible

        extend Reform::Form::ActiveModel::ModelValidations
        copy_validations_from WorkPackage

        private

        def user_allowed_to_access
          unless ::WorkPackage.visible(@user).exists?(model)
            message = not_found_error_message('WorkPackage', model.id)
            errors.add :error_not_found, message
          end
        end

        def user_allowed_to_edit
          errors.add :error_unauthorized, '' unless @can.allowed?(model, :edit)
        end

        def user_allowed_to_edit_parent
          if parent_changed?
            errors.add :error_unauthorized, '' unless @can.allowed?(model, :manage_subtasks)
          end
        end

        def parent_changed?
          model.changed.include? 'parent_id'
        end

        def lock_version_valid
          errors.add :error_conflict, '' if model.lock_version.nil? || model.lock_version_changed?
        end

        def readonly_attributes_unchanged
          changed_attributes = model.changed - WRITEABLE_ATTRIBUTES

          errors.add :error_readonly, changed_attributes unless changed_attributes.empty?
        end

        def assignee_visible
          people_visible :assignee, 'assigned_to_id', model.project.possible_assignees
        end

        def responsible_visible
          people_visible :responsible, 'responsible_id', model.project.possible_responsibles
        end

        def people_visible(attribute, id_attribute, list)
          id = model[id_attribute]

          return if id.nil? || !model.changed.include?(id_attribute)

          unless user_visible?(id, list)
            errors.add attribute, I18n.t('activerecord.errors.messages.inclusion', locale: :en)
          end
        end

        def user_visible?(user_id, list)
          user = User.find_by_id(user_id)

          !user.nil? && list.include?(user)
        end

        def not_found_error_message(object_type, id)
          "Couldn't find #{object_type} with id=#{id}"
        end
      end
    end
  end
end
