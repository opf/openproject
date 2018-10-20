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
      class AvailableRelationCandidatesAPI < ::API::OpenProjectAPI
        helpers ::API::V3::WorkPackages::AvailableRelationCandidatesHelper

        resources :available_relation_candidates do
          params do
            requires :query, type: String # either WP ID or part of its subject
            optional :type, type: String, default: "relates" # relation type
            optional :pageSize, type: Integer, default: 10
          end
          get do
            from = @work_package

            work_packages = work_package_queried params[:query], from, params[:type], params[:pageSize]

            # MySQL does not support LIMIT inside a subquery
            # As the representer wraps the work_packages scope
            # into a subquery and the scope contains a LIMIT we force
            # executing the scope via to_a.
            ::API::V3::WorkPackages::WorkPackageListRepresenter.new(
              work_packages.to_a,
              api_v3_paths.available_relation_candidates(from.id),
              current_user: current_user
            )
          end
        end
      end
    end
  end
end
