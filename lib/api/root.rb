#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module API
  class Root < ::API::RootAPI
    content_type 'hal+json', 'application/hal+json; charset=utf-8'
    format 'hal+json'
    formatter 'hal+json', API::Formatter.new
    default_format 'hal+json'

    parser :json, API::V3::Parser.new

    error_representer ::API::V3::Errors::ErrorRepresenter, 'hal+json'
    authentication_scope OpenProject::Authentication::Scope::API_V3

    OpenProject::Authentication.handle_failure(scope: API_V3) do |warden, _opts|
      e = grape_error_for warden.env, self
      error_message = I18n.t('api_v3.errors.code_401_wrong_credentials')
      api_error = ::API::Errors::Unauthenticated.new error_message
      representer = ::API::V3::Errors::ErrorRepresenter.new api_error

      e.error_response status: 401, message: representer.to_json, headers: warden.headers, log: false
    end

    version 'v3', using: :path do
      mount API::V3::Root
    end
  end
end
