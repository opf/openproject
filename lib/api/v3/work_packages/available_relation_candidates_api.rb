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
      class AvailableRelationCandidatesAPI < ::API::OpenProjectAPI
        resources :available_relation_candidates do
          params do
            requires :query, type: String # either WP ID or part of its subject
            optional :type, type: String, default: "relates" # relation type
          end
          get do
            from = @work_package

            query = WorkPackage
              .where("id = ? OR subject LIKE ?", params[:query].to_i, "%#{params[:query]}%")
              .where.not(id: from.id) # can't relate to itself
              .limit(10)

            if !Setting.cross_project_work_package_relations?
              query = query.where(project_id: from.project_id) # has to be same project
            end

            work_packages = query
              .reject do |to|
                rel = Relation.new(relation_type: params[:type], from: from, to: to)

                rel.shared_hierarchy? || rel.circular_dependency?
              end

            ::API::V3::WorkPackages::WorkPackageListRepresenter.new(
              work_packages,
              "/api/v3/work_package/#{@work_package.id}/available_relation_candidates",
              current_user: current_user
            )
          end
        end
      end
    end
  end
end
