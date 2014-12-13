#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Root class of the API
# This is the place for all API wide configuration, helper methods, exceptions
# rescuing, mounting of differnet API versions etc.

module API
  class Root < ::Cuba
    include API::Helpers
  end
end

API::Root.define do
  res.headers['Content-Type'] = 'application/json; charset=utf-8'

  begin
    # run authentication before each request
    authenticate

    on 'v3' do
      run API::V3::Root
    end
  rescue ActiveRecord::RecordNotFound => e
    api_error = ::API::Errors::NotFound.new(e.message)
    representer = ::API::V3::Errors::ErrorRepresenter.new(api_error)

    on default do
      res.status = api_error.code
      res.write representer.to_json
    end
  rescue ActiveRecord::StaleObjectError
    api_error = ::API::Errors::Conflict.new
    representer = ::API::V3::Errors::ErrorRepresenter.new(api_error)

    on default do
      res.status = api_error.code
      res.write representer.to_json
    end
  rescue ::API::Errors::ErrorBase => e
    representer = ::API::V3::Errors::ErrorRepresenter.new(e)

    on default do
      res.status = e.code
      res.write representer.to_json
    end
  end
end
