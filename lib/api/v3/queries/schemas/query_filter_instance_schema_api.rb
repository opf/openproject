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
    module Queries
      module Schemas
        class QueryFilterInstanceSchemaAPI < ::API::OpenProjectAPI
          resource :filter_instance_schemas do
            helpers do
              def collection_representer
                ::API::V3::Queries::Schemas::QueryFilterInstanceSchemaCollectionRepresenter
              end

              def single_representer
                ::API::V3::Queries::Schemas::QueryFilterInstanceSchemaRepresenter
              end
            end

            before do
              authorize(:view_work_packages, global: true, user: current_user)
            end

            get do
              filters = Query.new.available_filters

              collection_representer.new(filters,
                                         api_v3_paths.query_filter_instance_schemas,
                                         current_user: current_user)
            end

            params do
              requires :id, desc: 'Filter instance schema id'
            end

            route_param :id do
              get do
                ar_name = ::API::Utilities::QueryFiltersNameConverter
                          .to_ar_name(params[:id], refer_to_ids: true)

                filter_class = Query.find_registered_filter(ar_name)

                if filter_class
                  filter = filter_class.new context: OpenStruct.new(project: nil)
                  filter.name = ar_name

                  single_representer.new(filter,
                                         api_v3_paths.query_filter_instance_schema(params[:id]),
                                         current_user: current_user)
                else
                  raise ::API::Errors::NotFound.new
                end
              end
            end
          end
        end
      end
    end
  end
end
