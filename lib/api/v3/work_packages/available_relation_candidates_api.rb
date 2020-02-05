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
      class AvailableRelationCandidatesAPI < ::API::OpenProjectAPI
        helpers do
          def combined_params
            { filters: filters_param, pageSize: params[:pageSize] }.with_indifferent_access
          end

          def filters_param
            JSON::parse(params[:filters] || '[]')
              .concat([string_filter, type_filter])
          end

          def string_filter
            filter_param(:subject_or_id, '**', params[:query])
          end

          def type_filter
            filter_param(:relatable, params[:type], [@work_package.id.to_s])
          end

          def filter_param(key, operator, values)
            { key => { operator: operator, values: values } }.with_indifferent_access
          end
        end

        resources :available_relation_candidates do
          params do
            requires :query, type: String # either WP ID or part of its subject
            optional :type, type: String, default: ::Relation::TYPE_RELATES # relation type
            optional :pageSize, type: Integer, default: 10
          end
          get do
            service = WorkPackageCollectionFromQueryParamsService
                      .new(current_user)
                      .call(combined_params)

            if service.success?
              service.result
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
