#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      module Schema
        class SpecificWorkPackageSchema < BaseWorkPackageSchema
          attr_reader :work_package

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

          def assignable_values(property, current_user)
            case property
            when :status
              assignable_statuses_for(current_user)
            when :type
              if project.respond_to?(:types)
                project.types.includes(:color)
              end
            when :version
              @work_package.try(:assignable_versions) if project
            when :priority
              IssuePriority.active
            when :category
              project.categories if project.respond_to?(:categories)
            end
          end

          def assignable_custom_field_values(custom_field)
            case custom_field.field_format
            when 'list'
              custom_field.possible_values
            when 'version'
              assignable_values(:version, nil)
            end
          end

          private

          def contract
            @contract ||= begin
              ::WorkPackages::UpdateContract
                .new(work_package,
                     User.current)
            end
          end

          def assignable_statuses_for(user)
            status_origin = @work_package

            # do not allow to skip statuses without intermediately saving the work package
            # we therefore take the original status of the work_package, while preserving all
            # other changes to it (e.g. type, assignee, etc.)
            if @work_package.persisted? && @work_package.status_id_changed?
              status_origin = @work_package.clone
              status_origin.status = Status.find_by(id: @work_package.status_id_was)
            end

            status_origin.new_statuses_allowed_to(user)
          end
        end
      end
    end
  end
end
