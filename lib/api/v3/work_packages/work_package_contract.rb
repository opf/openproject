#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
        def self.writable_attributes
          @writable_attributes ||= %w(
            lock_version
            subject
            parent_id
            description
            start_date
            due_date
            status_id
            type_id
            assigned_to_id
            responsible_id
            priority_id
            category_id
            fixed_version_id
            done_ratio
            estimated_hours
          )
        end

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
        validate :estimated_hours_valid
        validate :done_ratio_valid

        extend Reform::Form::ActiveModel::ModelValidations
        copy_validations_from WorkPackage

        private

        def user_allowed_to_access
          unless ::WorkPackage.visible(@user).exists?(model)
            errors.add :error_not_found, I18n.t('api_v3.errors.code_404')
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
          changed_attributes = model.changed - self.class.writable_attributes

          errors.add :error_readonly, changed_attributes unless changed_attributes.empty?
        end

        def assignee_visible
          people_visible :assignee, 'assigned_to_id', model.project.possible_assignee_members
        end

        def responsible_visible
          people_visible :responsible, 'responsible_id', model.project.possible_responsible_members
        end

        def estimated_hours_valid
          if !model.leaf? && model.changed.include?('estimated_hours')
            errors.add :error_readonly, 'estimated_hours'
          end
        end

        def done_ratio_valid
          if model.changed.include?('done_ratio')
            # TODO Allow multiple errors as soon as they have separate messages
            if !model.leaf?
              errors.add :error_readonly, 'done_ratio'
            elsif Setting.work_package_done_ratio == 'status'
              errors.add :error_readonly, 'done_ratio'
            elsif Setting.work_package_done_ratio == 'disabled'
              errors.add :error_readonly, 'done_ratio'
            end
          end
        end

        def people_visible(attribute, id_attribute, list)
          id = model[id_attribute]

          return if id.nil? || !model.changed.include?(id_attribute)

          unless principal_visible?(id, list)
            errors.add attribute,
                       I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                              property: I18n.t("attributes.#{attribute}"))
          end
        end

        def principal_visible?(id, list)
          list.exists?(user_id: id)
        end
      end
    end
  end
end
