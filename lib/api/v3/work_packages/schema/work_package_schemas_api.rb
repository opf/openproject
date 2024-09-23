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

require "api/v3/work_packages/schema/typed_work_package_schema"
require "api/v3/work_packages/schema/work_package_sums_schema"
require "api/v3/work_packages/schema/work_package_schema_representer"
require "api/v3/work_packages/schema/work_package_sums_schema_representer"

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemasAPI < ::API::OpenProjectAPI
          resources :schemas do
            helpers do
              def raise404
                raise ::API::Errors::NotFound.new
              end

              def raise_invalid_query
                message = I18n.t("api_v3.errors.missing_or_malformed_parameter",
                                 parameter: "filters")

                raise ::API::Errors::InvalidQuery.new(message)
              end

              def parse_filter_for_project_type_pairs
                begin
                  filter = JSON::parse(params[:filters])
                rescue TypeError, JSON::ParseError
                  raise_invalid_query
                end

                service = ParseSchemaFilterParamsService
                          .new(user: current_user)
                          .call(filter)

                if service.success?
                  service.result
                else
                  raise_invalid_query
                end
              end

              def schemas_path_with_filters_params
                "#{api_v3_paths.work_package_schemas}?#{{ filters: params[:filters] }.to_query}"
              end
            end

            get do
              authorize_in_any_work_package(:view_work_packages)

              project_type_pairs = parse_filter_for_project_type_pairs

              schemas = project_type_pairs.map do |project, type|
                TypedWorkPackageSchema.new(project:, type:)
              end

              WorkPackageSchemaCollectionRepresenter.new(schemas,
                                                         self_link: schemas_path_with_filters_params,
                                                         current_user:)
            end

            # The schema identifier is an artificial identifier that is composed of a work package's
            # project and its type (separated by a dash).
            # This allows to have a separate schema URL for each kind of different work packages
            # but with better caching capabilities than simply using the work package id as
            # identifier for the schema.
            params do
              requires :project, desc: "Work package schema id"
              requires :type, desc: "Work package schema id"
            end
            namespace ":project-:type" do
              after_validation do
                begin
                  @project = Project.find(params[:project])
                  @type = Type.find(params[:type])
                rescue ActiveRecord::RecordNotFound
                  raise404
                end

                authorize_in_any_work_package(:view_work_packages, in_project: @project) do
                  raise404
                end
              end

              get do
                schema = TypedWorkPackageSchema.new(project: @project, type: @type)
                self_link = api_v3_paths.work_package_schema(@project.id, @type.id)
                represented_schema = WorkPackageSchemaRepresenter.create(schema,
                                                                         self_link:,
                                                                         current_user:)

                with_etag! represented_schema.json_cache_key

                represented_schema
              end
            end

            namespace "sums" do
              get do
                authorize_in_any_work_package(:view_work_packages) do
                  raise404
                end

                schema = WorkPackageSumsSchema.new
                @representer = WorkPackageSumsSchemaRepresenter.create(schema,
                                                                       current_user:)
              end
            end

            # Because the namespace declaration above does not match for shorter IDs we need
            # to catch those cases (e.g. '12' instead of '12-13') here and manually return 404
            # Otherwise we get a no route error
            namespace ":id" do
              get do
                raise404
              end
            end
          end
        end
      end
    end
  end
end
