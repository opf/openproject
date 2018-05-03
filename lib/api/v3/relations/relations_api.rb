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

require 'api/v3/relations/relation_representer'
require 'api/v3/relations/relation_collection_representer'

require 'relations/create_service'
require 'relations/update_service'

module API
  module V3
    module Relations
      class RelationsAPI < ::API::OpenProjectAPI
        helpers ::API::V3::Relations::RelationsHelper

        resources :relations do
          get do
            scope = Relation
                    .non_hierarchy
                    .includes(::API::V3::Relations::RelationRepresenter.to_eager_load)

            ::API::V3::Utilities::ParamsToQuery.collection_response(scope,
                                                                    current_user,
                                                                    params)
          end

          params do
            requires :id, type: Integer, desc: 'Relation id'
          end
          route_param :id do
            get do
              representer.new(
                Relation.find_by_id!(params[:id]),
                current_user: current_user,
                embed_links: true
              )
            end

            patch do
              rep = parse_representer.new Relation.new, current_user: current_user
              relation = rep.from_json request.body.read
              attributes = filter_attributes relation
              service = ::Relations::UpdateService.new relation: Relation.find_by_id!(params[:id]),
                                                       user: current_user
              call = service.call attributes: attributes,
                                  send_notifications: (params[:notify] != 'false')

              if call.success?
                representer.new call.result, current_user: current_user, embed_links: true
              else
                fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end
            end

            delete do
              project_id = project_id_for_relation params[:id]
              project = Project.find project_id

              authorize :manage_work_package_relations, context: project

              Relation.destroy params[:id]
              status 204
            end
          end
        end
      end
    end
  end
end
