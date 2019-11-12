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
  class ProjectsAPI < ::API::OpenProjectAPI
    resources :projects do
      helpers do
        def visible_projects
          Project
            .visible(current_user)
            .has_module(:bcf)
        end
      end

      get do
        visible_projects
          .map do |project|
          Bcf::API::V2_1::Projects::SingleRepresenter
            .new(project)
        end
      end

      route_param :id, regexp: /\A(\d+)\z/ do
        after_validation do
          @project = visible_projects
                     .find(params[:id])
        end

        get do
          Bcf::API::V2_1::Projects::SingleRepresenter
            .new(@project)
        end

        put do
          parse_call = Bcf::API::V2_1::ParseResourceParamsService
                       .new(current_user, model: Project)
                       .call(request_body)

          update_call = ::Projects::UpdateService
                         .new(user: current_user, model: @project)
                         .call(parse_call.result)

          if update_call.success?
            Bcf::API::V2_1::Projects::SingleRepresenter
              .new(update_call.result)
          else
            fail ::API::Errors::ErrorBase.create_and_merge_errors(update_call.errors)
          end
        end
      end
    end
  end
end