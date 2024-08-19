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

# Root class of the API
# This is the place for all API wide configuration, helper methods, exceptions
# rescuing, mounting of different API versions etc.

module Bim::Bcf
  module API
    class Root < ::API::RootAPI
      format :json
      formatter :json, ::API::Formatter.new

      default_format :json

      error_representer ::Bim::Bcf::API::V2_1::Errors::ErrorRepresenter, "application/json; charset=utf-8"
      error_formatter :json, ::Bim::Bcf::API::ErrorFormatter::Json

      authentication_scope OpenProject::Authentication::Scope::BCF_V2_1

      version "2.1", using: :path do
        # /auth
        mount ::Bim::Bcf::API::V2_1::AuthAPI
        # /current-user
        mount ::Bim::Bcf::API::V2_1::CurrentUserAPI
        # /projects
        mount ::Bim::Bcf::API::V2_1::ProjectsAPI
      end
    end
  end
end
