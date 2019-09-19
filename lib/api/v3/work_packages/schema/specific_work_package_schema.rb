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

module API
  module V3
    module WorkPackages
      module Schema
        class SpecificWorkPackageSchema < BaseWorkPackageSchema
          attr_reader :work_package
          include ::Concerns::AssignableCustomFieldValues
          include ::Concerns::AssignableValuesContract

          def initialize(work_package:)
            @work_package = work_package
          end

          delegate :project_id,
                   :project,
                   :type,
                   :id,
                   :milestone?,
                   :available_custom_fields,
                   to: :@work_package

          def no_caching?
            true
          end

          private

          def contract
            @contract ||= begin
              klass = if work_package.new_record?
                        ::WorkPackages::CreateContract
                      else
                        ::WorkPackages::UpdateContract
                      end

              klass
                .new(work_package,
                     User.current)
            end
          end

          def assignable_categories
            project.categories if project.respond_to?(:categories)
          end

          def assignable_priorities
            IssuePriority.active
          end

          def assignable_versions
            @work_package.try(:assignable_versions) if project
          end

          def assignable_types
            if project.nil?
              Type.includes(:color)
            else
              project.types.includes(:color)
            end
          end

          def assignable_statuses
            status_origin = @work_package

            # do not allow to skip statuses without intermediately saving the work package
            # we therefore take the original status of the work_package, while preserving all
            # other changes to it (e.g. type, assignee, etc.)
            if @work_package.persisted? && @work_package.status_id_changed?
              status_origin = @work_package.clone
              status_origin.status = Status.find_by(id: @work_package.status_id_was)
            end

            status_origin.new_statuses_allowed_to(User.current)
          end
        end
      end
    end
  end
end
