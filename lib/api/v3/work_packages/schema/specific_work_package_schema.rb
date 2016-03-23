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
      module Schema
        class SpecificWorkPackageSchema < BaseWorkPackageSchema
          def initialize(work_package:)
            @work_package = work_package
          end

          delegate :project,
                   :type,
                   :id,
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
              @work_package.try(:assignable_versions)
            when :priority
              IssuePriority.active
            when :category
              project.categories
            end
          end

          def available_custom_fields
            # we might have received a (currently) invalid work package
            return [] if project.nil? || type.nil?

            project.all_work_package_custom_fields.to_a & type.custom_fields.to_a
          end

          def writable?(property)
            if [:percentage_done,
                :estimated_time,
                :start_date,
                :due_date,
                :priority].include? property
              return false unless @work_package.leaf?
            end

            super
          end

          private

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
