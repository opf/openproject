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

module AI
  module TextTransforms
    class ResolveContext
      def initialize(user:)
        @user = user
      end

      def call(work_package_id: nil, project_id: nil, type_id: nil)
        if work_package_id
          work_package_context(work_package_id)
        elsif project_id
          new_work_package_context(project_id, type_id)
        else
          ServiceResult.success(result: Context.none)
        end
      end

      private

      attr_reader :user

      def work_package_context(id)
        work_package = WorkPackage.visible(user).find_by(id:)
        return not_found(WorkPackage) unless work_package
        return forbidden(work_package) unless user.allowed_in_work_package?(:edit_work_packages, work_package)

        ServiceResult.success(result: Context.for_work_package(work_package))
      end

      def new_work_package_context(project_id, type_id)
        project = Project.visible(user).find_by(id: project_id)
        return not_found(Project) unless project
        return forbidden(project) unless user.allowed_in_project?(:add_work_packages, project)

        type = project.enabled_types.find_by(id: type_id)
        return not_found(Type) unless type

        ServiceResult.success(result: Context.for_new_work_package(project:, type:))
      end

      def not_found(model_class)
        failure(model_class.new, :error_not_found)
      end

      def forbidden(record)
        failure(record, :error_unauthorized)
      end

      def failure(record, error)
        errors = ActiveModel::Errors.new(record)
        errors.add(:base, error)
        ServiceResult.failure(errors:)
      end
    end
  end
end
