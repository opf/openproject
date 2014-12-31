#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
  class Root < Grape::API
    prefix :api

    class Formatter
      def call(object, _env)
        object.respond_to?(:to_json) ? object.to_json : MultiJson.dump(object)
      end
    end

    class Parser
      def call(object, _env)
        MultiJson.load(object)
      rescue MultiJson::ParseError => e
        error = ::API::Errors::ParseError.new(e.message)
        representer = ::API::V3::Errors::ErrorRepresenter.new(error)

        throw :error, status: 400, message: representer.to_json
      end
    end

    content_type 'hal+json', 'application/hal+json; charset=utf-8'
    content_type :json,      'application/json; charset=utf-8'
    format 'hal+json'
    formatter 'hal+json', Formatter.new

    parser :json, Parser.new

    helpers do
      def current_user
        return User.current if Rails.env.test?
        user_id = env['rack.session']['user_id']
        User.current = user_id ? User.find(user_id) : User.anonymous
      end

      def authenticate
        raise API::Errors::Unauthenticated if current_user.nil? || current_user.anonymous? if Setting.login_required?
      end

      def authorize(permission, context: nil, global: false, user: current_user, allow: true)
        is_authorized = AuthorizationService.new(permission, context: context, global: global, user: user).call
        raise API::Errors::Unauthorized unless is_authorized && allow
        is_authorized
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      api_error = ::API::Errors::NotFound.new(e.message)
      representer = ::API::V3::Errors::ErrorRepresenter.new(api_error)
      error_response(status: api_error.code, message: representer.to_json)
    end

    rescue_from ActiveRecord::StaleObjectError do
      api_error = ::API::Errors::Conflict.new
      representer = ::API::V3::Errors::ErrorRepresenter.new(api_error)
      error_response(status: api_error.code, message: representer.to_json)
    end

    rescue_from ::API::Errors::ErrorBase, rescue_subclasses: true do |e|
      representer = ::API::V3::Errors::ErrorRepresenter.new(e)
      error_response(status: e.code, message: representer.to_json)
    end

    # run authentication before each request
    before do
      authenticate
    end

    mount API::V3::Root
  end
end
