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

module API::V3::OAuth
  class OAuthApplicationsAPI < ::API::OpenProjectAPI
    resources :oauth_applications do
      route_param :oauth_application_id, type: Integer, desc: "OAuth application id" do
        after_validation do
          authorize_admin
          @application = ::Doorkeeper::Application.find(params[:oauth_application_id])
        end

        get &::API::V3::Utilities::Endpoints::Show
               .new(model: ::Doorkeeper::Application,
                    render_representer: ::API::V3::OAuth::OAuthApplicationsRepresenter)
               .mount
      end
    end
  end
end
