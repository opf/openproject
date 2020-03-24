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

# Root class of the API
# This is the place for all API wide configuration, helper methods, exceptions
# rescuing, mounting of differnet API versions etc.

require 'open_project/authentication'

module API
  class RootAPI < Grape::API
    include OpenProject::Authentication::Scope
    extend API::Utilities::GrapeHelper

    content_type :json, 'application/json; charset=utf-8'

    use OpenProject::Authentication::Manager

    helpers API::Caching::Helpers
    helpers do
      def current_user
        User.current
      end

      def warden
        env['warden']
      end

      ##
      # Helper to access only the declared
      # params to avoid unvalidated access
      # (e.g., in before blocks)
      def declared_params
        declared(params)
      end

      def request_body
        env['api.request.body']
      end

      def authenticate
        User.current = warden.authenticate! scope: authentication_scope

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

      def authorize_admin
        authorize_by_with_raise(current_user.admin? && (current_user.active? || current_user.is_a?(SystemUser)))
      end

      def authorize_logged_in
        authorize_by_with_raise(current_user.logged? && current_user.active? || current_user.is_a?(SystemUser))
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
                   .response_header(scope: authentication_scope, request_headers: env)

        { 'WWW-Authenticate' => header }
      end
    end

    def self.error_representer(klass, content_type)
      # Have the vars available in the instances via helpers.
      helpers do
        define_method(:error_representer, -> { klass })
        define_method(:error_content_type, -> { content_type })
      end
    end

    def self.authentication_scope(sym)
      # Have the scope available in the instances
      # via a helper.
      helpers do
        define_method(:authentication_scope, -> { sym })
      end
    end

    error_response ActiveRecord::RecordNotFound, ::API::Errors::NotFound, log: false
    error_response ActiveRecord::StaleObjectError, ::API::Errors::Conflict, log: false
    error_response NotImplementedError, ::API::Errors::NotImplemented, log: false

    error_response MultiJson::ParseError, ::API::Errors::ParseError

    error_response ::API::Errors::Unauthenticated, headers: auth_headers, log: false
    error_response ::API::Errors::ErrorBase, rescue_subclasses: true, log: false

    # Handle grape validation errors
    error_response ::Grape::Exceptions::ValidationErrors, ::API::Errors::BadRequest, log: false

    # Handle connection timeouts with appropriate payload
    error_response ActiveRecord::ConnectionTimeoutError,
                   ::API::Errors::InternalError,
                   log: ->(exception) do
                     payload = ::OpenProject::Logging::ThreadPoolContextBuilder.build!
                     ::OpenProject.logger.error exception, reference: :APIv3, payload: payload
                   end

    # hide internal errors behind the same JSON response as all other errors
    # only doing it in production to allow for easier debugging
    if Rails.env.production?
      error_response StandardError, ::API::Errors::InternalError, rescue_subclasses: true
    end

    # run authentication before each request
    after_validation do
      authenticate
      set_localization
      enforce_content_type
    end
  end
end
