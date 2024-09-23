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

module Bim::Bcf::API::V2_1
  class TopicsAPI < ::API::OpenProjectAPI
    resources :topics do
      helpers do
        def topics
          ::Bim::Bcf::Issue.of_project(@project)
        end

        def transform_attributes(attributes)
          wp_attributes = ::Bim::Bcf::Issues::TransformAttributesService
                            .new(@project)
                            .call(attributes)
                            .result

          attributes
            .slice(*::Bim::Bcf::Issue::SETTABLE_ATTRIBUTES)
            .merge(wp_attributes)
        end

        # In a put request, every non required and non provided
        # parameter needs to be nilled. As we cannot nil type, status and priority
        # as they are required for a work package we use the default values.
        def default_put_params
          {
            index: nil,
            assigned_to: nil,
            description: nil,
            due_date: nil,
            subject: nil,
            type: @project.types.default.first,
            status: Status.default,
            priority: IssuePriority.default
          }
        end
      end

      after_validation do
        authorize_in_project(:view_linked_issues, project: @project)
      end

      get &::Bim::Bcf::API::V2_1::Endpoints::Index
             .new(model: Bim::Bcf::Issue,
                  api_name: "Topics",
                  scope: -> { topics })
             .mount

      post &::Bim::Bcf::API::V2_1::Endpoints::Create
             .new(model: Bim::Bcf::Issue,
                  api_name: "Topics",
                  params_modifier: ->(attributes) {
                    transform_attributes(attributes)
                      .merge(project: @project)
                  })
             .mount

      route_param :topic_uuid, regexp: /\A[a-f0-9-]+\z/ do
        after_validation do
          @issue = topics.find_by!(uuid: params[:topic_uuid])
        end

        get &::Bim::Bcf::API::V2_1::Endpoints::Show
              .new(model: Bim::Bcf::Issue,
                   api_name: "Topics")
              .mount

        put &::Bim::Bcf::API::V2_1::Endpoints::Update
               .new(model: Bim::Bcf::Issue,
                    api_name: "Topics",
                    params_modifier: ->(attributes) {
                      transform_attributes(attributes)
                        .reverse_merge(default_put_params)
                    })
               .mount

        delete &::Bim::Bcf::API::V2_1::Endpoints::Delete
                  .new(model: Bim::Bcf::Issue,
                       api_name: "Topics")
                  .mount

        mount ::Bim::Bcf::API::V2_1::Viewpoints::API
        mount ::Bim::Bcf::API::V2_1::Comments::API
      end
    end
  end
end
