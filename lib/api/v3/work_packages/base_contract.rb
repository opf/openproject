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

module API
  module V3
    module WorkPackages
      class BaseContract < ::API::Contracts::ModelContract
        attribute :subject
        attribute :description
        attribute :start_date, :due_date
        attribute :status_id
        attribute :type_id
        attribute :priority_id
        attribute :category_id
        attribute :fixed_version_id
        attribute :lock_version

        attribute :parent_id do
          if model.changed.include? 'parent_id'
            errors.add :error_unauthorized, '' unless @can.allowed?(model, :manage_subtasks)
          end
        end

        attribute :assigned_to_id do
          validate_people_visible :assignee,
                                  'assigned_to_id',
                                  model.project.possible_assignee_members
        end

        attribute :responsible_id do
          validate_people_visible :responsible,
                                  'responsible_id',
                                  model.project.possible_responsible_members
        end

        attribute :done_ratio do
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

        attribute :estimated_hours do
          if !model.leaf? && model.changed.include?('estimated_hours')
            errors.add :error_readonly, 'estimated_hours'
          end
        end

        attribute :start_date do
          if !model.leaf? && model.changed.include?('start_date')
            errors.add :error_readonly, 'start_date'
          end
        end

        attribute :due_date do
          if !model.leaf? && model.changed.include?('due_date')
            errors.add :error_readonly, 'due_date'
          end
        end

        def initialize(object, user)
          super(object)

          @user = user
          @can = WorkPackagePolicy.new(user)
        end

        extend Reform::Form::ActiveModel::ModelValidations
        copy_validations_from WorkPackage

        private

        def validate_people_visible(attribute, id_attribute, list)
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
