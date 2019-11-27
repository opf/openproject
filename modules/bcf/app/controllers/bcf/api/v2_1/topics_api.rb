#-- encoding: UTF-8

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

module Bcf::API::V2_1
  class TopicsAPI < ::API::OpenProjectAPI
    resources :topics do
      helpers do
        def topics
          Bcf::Issue.of_project(@project)
        end
      end

      after_validation do
        authorize :view_linked_issues, context: @project
      end

      get &::Bcf::API::V2_1::Endpoints::Index
             .new(model: Bcf::Issue,
                  api_name: 'Topics',
                  scope: -> { topics })
             .mount

      post &::Bcf::API::V2_1::Endpoints::Create
             .new(model: Bcf::Issue,
                  api_name: 'Topics',
                  params_modifier: ->(attributes) {
                    attributes[:project_id] = @project.id

                    wp_attributes = Bcf::Issues::TransformAttributesService
                                    .new
                                    .call(attributes)
                                    .result

                    attributes
                      .slice(:stage,
                             :index,
                             :labels)
                      .merge(wp_attributes)
                  })
             .mount

      route_param :topic_uuid, regexp: /\A[a-f0-9\-]+\z/ do
        after_validation do
          @issue = topics.find_by_uuid!(params[:topic_uuid])
        end

        get &::Bcf::API::V2_1::Endpoints::Show
              .new(model: Bcf::Issue,
                   api_name: 'Topics')
              .mount

        delete &::Bcf::API::V2_1::Endpoints::Delete
              .new(model: Bcf::Issue,
                   api_name: 'Topics')
              .mount

        mount Bcf::API::V2_1::Viewpoints::API
      end
    end
  end
end
