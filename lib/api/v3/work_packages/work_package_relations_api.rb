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
    module WorkPackages
      class WorkPackageRelationsAPI < ::API::OpenProjectAPI
        helpers ::API::V3::Relations::RelationsHelper

        resources :relations do
          ##
          # @todo Redirect to relations endpoint as soon as `list relations` API endpoint
          #       including filters is complete.
          get do
            query = ::Queries::Relations::RelationQuery.new(user: current_user)

            relations = query
                        .where(:involved, '=', @work_package.id)
                        .results
                        .non_hierarchy

            ::API::V3::Relations::RelationCollectionRepresenter.new(
              relations,
              api_v3_paths.work_package_relations(@work_package.id),
              current_user: current_user
            )
          end

          post do
            rep = parse_representer.new Relation.new, current_user: current_user
            relation = rep.from_json request.body.read
            service = ::Relations::CreateService.new user: current_user
            call = service.call relation, send_notifications: (params[:notify] != 'false')

            if call.success?
              representer.new call.result, current_user: current_user, embed_links: true
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.all_errors.reject(&:empty?).first)
            end
          end
        end
      end
    end
  end
end
