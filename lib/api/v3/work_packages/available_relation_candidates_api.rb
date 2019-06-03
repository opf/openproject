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

            # Set project to nil to find all work packages
            # combined with the project condition of +work_package_scope+
            query = Query.new_default(name: '_', project: nil)

            service = ::API::V3::UpdateQueryFromV3ParamsService
              .new(query, current_user)
              .call(params)

            if service.success?
              # MySQL does not support LIMIT inside a subquery
              # As the representer wraps the work_packages scope
              # into a subquery and the scope contains a LIMIT we force
              # executing the scope via to_a.
              query = service.result

              # Override the query filter
              query.add_filter 'subject_or_id', '**', query

              relation_scope = work_package_scope(from, params[:type])
              results = query.results.sorted_work_packages.merge(relation_scope)

              ::API::V3::WorkPackages::WorkPackageListRepresenter.new(
                results.to_a,
                api_v3_paths.available_relation_candidates(from.id),
                current_user: current_user
              )
            else
              api_errors = service.errors.full_messages.map do |message|
                ::API::Errors::InvalidQuery.new(message)
              end

              raise ::API::Errors::MultipleErrors.create_if_many api_errors
            end
          end
        end
      end
    end
  end
end
