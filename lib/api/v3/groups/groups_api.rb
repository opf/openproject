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
    module Groups
      class GroupsAPI < ::API::OpenProjectAPI
        resources :groups do
          after_validation do
            authorize_in_any_project(%i[view_members manage_members])
          end

          get &::API::V3::Utilities::Endpoints::SqlFallbackedIndex
                 .new(model: Group)
                 .mount
          post &::API::V3::Utilities::Endpoints::Create
                  .new(model: Group)
                  .mount

          route_param :id, type: Integer, desc: "Group ID" do
            after_validation do
              @group = Group.visible(current_user).find(params[:id])
            end

            get &::API::V3::Utilities::Endpoints::Show
                   .new(model: Group)
                   .mount
            patch &::API::V3::Utilities::Endpoints::Update
                     .new(model: Group)
                     .mount
            delete &::API::V3::Utilities::Endpoints::Delete
                     .new(model: Group,
                          success_status: 202)
                     .mount
          end
        end
      end
    end
  end
end
