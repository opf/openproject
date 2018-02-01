#-- encoding: UTF-8
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

# Root class of the API
# This is the place for all API wide configuration, helper methods, exceptions
# rescuing, mounting of differnet API versions etc.

require 'open_project/authentication'

module API
  class Root < Grape::API
    include OpenProject::Authentication::Scope
    extend API::Utilities::GrapeHelper

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
        error = ::API::Errors::ParseError.new(details: e.message)
        representer = ::API::V3::Errors::ErrorRepresenter.new(error)

        throw :error, status: 400, message: representer.to_json
      end
    end

    content_type 'hal+json', 'application/hal+json; charset=utf-8'
    content_type :json,      'application/json; charset=utf-8'
    format 'hal+json'
    formatter 'hal+json', Formatter.new

    parser :json, Parser.new

    use OpenProject::Authentication::Manager

    helpers API::Caching::Helpers
    helpers do
      def current_user
        User.current
      end

      def warden
        env['warden']
      end

      def request_body
        env['api.request.body']
      end

      def authenticate
        warden.authenticate! scope: API_V3

        User.current = warden.user scope: API_V3

        if Setting.login_required? and not logged_in?
          raise ::API::Errors::Unauthenticated
        end
      end

      def set_localization
        SetLocalizationService.new(User.current, env['HTTP_ACCEPT_LANGUAGE']).call
      end

      # Global helper to set allowed content_types
      # This may be overriden when multipart is allowed (file uploads)
      def allowed_content_types
        %w(application/json application/hal+json)
      end

      def enforce_content_type
        # Content-Type is not present in GET
        return if request.get?

        # Raise if missing header
        content_type = request.content_type
        error!('Missing content-type header', 406) unless content_type.present?

        # Allow JSON and JSON+HAL per default
        # and anything that each endpoint may optionally add to that
        if content_type.present?
          allowed_content_types.each do |mime|
            # Content-Type header looks like this (e.g.,)
            # application/json;encoding=utf8
            return if content_type.start_with?(mime)
          end
        end

        bad_type = content_type.presence || I18n.t('api_v3.errors.missing_content_type')
        message = I18n.t('api_v3.errors.invalid_content_type',
                         content_type: allowed_content_types.join(" "),
                         actual: bad_type)

        fail ::API::Errors::UnsupportedMediaType, message
      end

      def logged_in?
        # An admin SystemUser is anonymous but still a valid user to be logged in.
        current_user && (current_user.admin? || !current_user.anonymous?)
      end

      def authorize(permission, context: nil, global: false, user: current_user, &block)
        auth_service = AuthorizationService.new(permission,
                                                context: context,
                                                global: global,
                                                user: user)

        authorize_by_with_raise auth_service, &block
      end

      def authorize_by_with_raise(callable)
        is_authorized = callable.respond_to?(:call) ? callable.call : callable

        return true if is_authorized

        if block_given?
          yield
        else
          raise API::Errors::Unauthorized
        end

        false
      end

      # checks whether the user has
      # any of the provided permission in any of the provided
      # projects
      def authorize_any(permissions, projects: nil, global: false, user: current_user, &block)
        raise ArgumentError if projects.nil? && !global

        projects = Array(projects)

        authorized = permissions.any? do |permission|
          if global
            authorize(permission, global: true, user: user) do
              false
            end
          else
            allowed_projects = Project.allowed_to(user, permission)
            !(allowed_projects & projects).empty?
          end
        end

        authorize_by_with_raise(authorized, &block)
      end

      def raise_invalid_query_on_service_failure
        service = yield

        if service.success?
          service
        else
          api_errors = service.errors.full_messages.map do |message|
            ::API::Errors::InvalidQuery.new(message)
          end

          raise ::API::Errors::MultipleErrors.create_if_many api_errors
        end
      end
    end

    def self.auth_headers
      lambda do
        header = OpenProject::Authentication::WWWAuthenticate
                 .response_header(scope: API_V3, request_headers: env)

        { 'WWW-Authenticate' => header }
      end
    end

    ##
    # Return JSON error response on authentication failure.
    OpenProject::Authentication.handle_failure(scope: API_V3) do |warden, _opts|
      e = grape_error_for warden.env, self
      error_message = I18n.t('api_v3.errors.code_401_wrong_credentials')
      api_error = ::API::Errors::Unauthenticated.new error_message
      representer = ::API::V3::Errors::ErrorRepresenter.new api_error

      e.error_response status: 401, message: representer.to_json, headers: warden.headers, log: false
    end

    error_response ActiveRecord::RecordNotFound, ::API::Errors::NotFound.new
    error_response ActiveRecord::StaleObjectError, ::API::Errors::Conflict.new

    error_response MultiJson::ParseError, ::API::Errors::ParseError.new

    error_response ::API::Errors::Unauthenticated, headers: auth_headers, log: false
    error_response ::API::Errors::ErrorBase, rescue_subclasses: true, log: false

    # hide internal errors behind the same JSON response as all other errors
    # only doing it in production to allow for easier debugging
    if Rails.env.production?
      error_response StandardError, ::API::Errors::InternalError.new, rescue_subclasses: true
    end

    # run authentication before each request
    before do
      authenticate
      set_localization
      enforce_content_type
    end

    version 'v3', using: :path do
      mount API::V3::Root
    end
  end
end
