#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
      module EagerLoading
        class Project < Base
          def apply(work_package)
            work_package.project = project_for(work_package.project_id)
            work_package.parent.project = project_for(work_package.parent.project_id) if work_package.parent

            work_package.children.each do |child|
              child.project = project_for(child.project_id)
            end
          end

          private

          def project_for(project_id)
            projects_by_id[project_id]
          end

          def projects_by_id
            @projects_by_id ||= begin
              ::Project
                .includes(:enabled_modules)
                .where(id: project_ids)
                .to_a
                .map { |p| [p.id, p] }
                .to_h
            end
          end

          def project_ids
            work_packages.map do |work_package|
              [work_package.project_id, work_package.parent && work_package.parent.project_id] +
                work_package.children.map(&:project_id)
            end.flatten.uniq.compact
          end
        end
      end
    end
  end
end
