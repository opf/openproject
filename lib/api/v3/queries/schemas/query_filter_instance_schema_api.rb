#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
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

            after_validation do
              authorize_in_any_work_package(:view_work_packages)
            end

            get do
              filters = Query.new.available_filters

              collection_representer.new(filters,
                                         self_link: api_v3_paths.query_filter_instance_schemas,
                                         current_user:)
            end

            route_param :id, type: String, regexp: /\A\w+\z/, desc: "Filter schema ID" do
              get do
                ar_name = ::API::Utilities::QueryFiltersNameConverter
                          .to_ar_name(params[:id], refer_to_ids: true)
                filter_class = Query.find_registered_filter(ar_name)

                raise ::API::Errors::NotFound.new if filter_class.nil?

                filter = filter_class.create! name: ar_name, context: OpenStruct.new(project: nil)

                single_representer.new(filter,
                                       self_link: api_v3_paths.query_filter_instance_schema(params[:id]),
                                       current_user:)
              end
            end
          end
        end
      end
    end
  end
end
