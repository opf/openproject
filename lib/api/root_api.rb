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

require "open_project/authentication"

module API
  class RootAPI < Grape::API
    include OpenProject::Authentication::Scope
    include ::API::AppsignalAPI
    extend API::Utilities::GrapeHelper

    insert_before Grape::Middleware::Error,
                  ::GrapeLogging::Middleware::RequestLogger,
                  { instrumentation_key: "openproject_grape_logger" }

    content_type :json, "application/json; charset=utf-8"

    use OpenProject::Authentication::Manager

    helpers API::Caching::Helpers
    module Helpers
      def current_user
        User.current
      end

      def warden
        env["warden"]
      end

      ##
      # Helper to access only the declared
      # params to avoid unvalidated access
      # (e.g., in before blocks)
      def declared_params
        declared(params)
      end

      def request_body
        env["api.request.body"]
      end

      def authenticate
        User.current = warden.authenticate! scope: authentication_scope

        if Setting.login_required? && !logged_in? && !allowed_unauthenticated_route?
          raise ::API::Errors::Unauthenticated
        end
      end

      def allowed_unauthenticated_route?
        false
      end

      def set_localization
        SetLocalizationService.new(User.current, env["HTTP_ACCEPT_LANGUAGE"]).call
      end

      # Global helper to set allowed content_types
      # This may be overridden when multipart is allowed (file uploads)
      def allowed_content_types
        %w(application/json application/hal+json)
      end

      # Prevent committing the session
      # This prevents an unnecessary write when accessing the API
      def skip_session_write
        request.session_options[:skip] = true
      end

      def enforce_content_type
        # Content-Type is not present in GET or DELETE requests
        return if request.get? || request.delete?

        # Raise if missing header
        content_type = request.content_type
        error!("Missing content-type header", 406, { "Content-Type" => "text/plain" }) if content_type.blank?

        # Allow JSON and JSON+HAL per default
        # and anything that each endpoint may optionally add to that
        if content_type.present?
          allowed_content_types.each do |mime|
            # Content-Type header looks like this (e.g.,)
            # application/json;encoding=utf8
            return if content_type.start_with?(mime)
          end
        end

        bad_type = content_type.presence || I18n.t("api_v3.errors.missing_content_type")
        message = I18n.t("api_v3.errors.invalid_content_type",
                         content_type: allowed_content_types.join(" "),
                         actual: bad_type)

        fail ::API::Errors::UnsupportedMediaType, message
      end

      def logged_in?
        # An admin SystemUser is anonymous but still a valid user to be logged in.
        current_user && (current_user.admin? || !current_user.anonymous?)
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

      # Checks that the current user has the given permission on the given project or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @param project [Project] the project the permission needs to be checked on
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_in_project(permission_or_permissions, project:, user: current_user, &)
        permissions = Array.wrap(permission_or_permissions)
        authorized = permissions.any? do |permission|
          user.allowed_in_project?(permission, project)
        end

        authorize_by_with_raise(authorized, &)
      end

      # Checks that the current user has the given permission in any of the given projects or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @param projects [[Project]] the projects the permission needs to be checked on
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_in_projects(permission_or_permissions, projects:, user: current_user, &)
        raise ArgumentError if projects.blank?

        permissions = Array.wrap(permission_or_permissions)

        projects = Array(projects)

        authorized = permissions.any? do |permission|
          allowed_projects = Project.allowed_to(user, permission)
          projects.intersect?(allowed_projects)
        end

        authorize_by_with_raise(authorized, &)
      end

      # Checks that the current user has the given permission on any project or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_in_any_project(permission_or_permissions, user: current_user, &)
        permissions = Array.wrap(permission_or_permissions)
        authorized = permissions.any? do |permission|
          user.allowed_in_any_project?(permission)
        end

        authorize_by_with_raise(authorized, &)
      end

      # Checks that the current user has the given permission on any work package or project or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_in_any_work_package(permission_or_permissions, user: current_user, in_project: nil, &)
        permissions = Array.wrap(permission_or_permissions)
        authorized = permissions.any? do |permission|
          user.allowed_in_any_work_package?(permission, in_project:)
        end

        authorize_by_with_raise(authorized, &)
      end

      # Checks that the current user has the given permission on the given work package or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @param work_package [Project] the work package the permission needs to be checked on
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_in_work_package(permission_or_permissions, work_package:, user: current_user, &)
        permissions = Array.wrap(permission_or_permissions)
        authorized = permissions.any? do |permission|
          user.allowed_in_work_package?(permission, work_package)
        end

        authorize_by_with_raise(authorized, &)
      end

      # Checks that the current user has the given permission globally or raise {API::Errors::Unauthorized}.
      #
      # @param permission_or_permissions [String, [String], Hash] the permission name, an array of permissions or a hash
      #   with controller and action keys. When an array of permissions is given, the user needs to have at least one of
      #   those permissions, not all.
      #
      # @raise [API::Errors::Unauthorized] when permission is not met
      def authorize_globally(permission_or_permissions, user: current_user, &)
        permissions = Array.wrap(permission_or_permissions)
        authorized = permissions.any? do |permission|
          user.allowed_globally?(permission)
        end

        authorize_by_with_raise(authorized, &)
      end

      def authorize_admin
        authorize_by_with_raise(current_user.admin? && (current_user.active? || current_user.is_a?(SystemUser)))
      end

      def authorize_logged_in
        authorize_by_with_raise((current_user.logged? && current_user.active?) || current_user.is_a?(SystemUser))
      end

      def raise_query_errors(object)
        api_errors = object.errors.full_messages.map do |message|
          ::API::Errors::InvalidQuery.new(message)
        end

        raise ::API::Errors::MultipleErrors.create_if_many api_errors
      end

      def raise_invalid_query_on_service_failure
        service = yield

        if service.success?
          service
        else
          raise_query_errors(service)
        end
      end
    end

    helpers Helpers

    def self.auth_headers
      lambda do
        header = OpenProject::Authentication::WWWAuthenticate
                   .response_header(scope: authentication_scope, request_headers: env)

        { "WWW-Authenticate" => header }
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
                     ::OpenProject.logger.error exception, reference: :APIv3, payload:
                   end

    # hide internal errors behind the same JSON response as all other errors
    # only doing it in production to allow for easier debugging
    if Rails.env.production?
      error_response StandardError, ::API::Errors::InternalError, rescue_subclasses: true
    end

    # run authentication before each request
    after_validation do
      skip_session_write
      authenticate
      set_localization
      enforce_content_type
      ::OpenProject::Appsignal.tag_request(request:)
    end
  end
end
