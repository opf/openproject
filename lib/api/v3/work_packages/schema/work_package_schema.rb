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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchema
          attr_reader :project, :type

          def initialize(work_package: nil, project: nil, type: nil)
            raise ArgumentError unless work_package || (project && type)

            @project = project || work_package.project
            @type = type || work_package.type
            @work_package = work_package
          end

          def assignable_statuses_for(user)
            return nil if @work_package.nil?

            status_origin = @work_package

            # do not allow to skip statuses without intermediately saving the work package
            # we therefore take the original status of the work_package, while preserving all
            # other changes to it (e.g. type, assignee, etc.)
            if @work_package.persisted? && @work_package.status_id_changed?
              status_origin = @work_package.clone
              status_origin.status = Status.find_by_id(@work_package.status_id_was)
            end

            status_origin.new_statuses_allowed_to(user)
          end

          def assignable_types
            project.try(:types)
          end

          def assignable_versions
            @work_package.try(:assignable_versions)
          end

          def assignable_priorities
            IssuePriority.active
          end

          def assignable_categories
            project.categories
          end

          def available_custom_fields
            # we might have received a (currently) invalid work package
            return [] if @project.nil? || @type.nil?

            project.all_work_package_custom_fields & type.custom_fields.all
          end

          def percentage_done_writable?
            if Setting.work_package_done_ratio == 'status' ||
               Setting.work_package_done_ratio == 'disabled'
              return false
            end
            nil_or_leaf?(@work_package)
          end

          def estimated_time_writable?
            nil_or_leaf?(@work_package)
          end

          def start_date_writable?
            nil_or_leaf?(@work_package)
          end

          def due_date_writable?
            nil_or_leaf?(@work_package)
          end

          def nil_or_leaf?(work_package)
            work_package.nil? || work_package.leaf?
          end
        end
      end
    end
  end
end
