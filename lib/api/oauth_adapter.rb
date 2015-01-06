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

# Adapter for Doorkeeper to add a second,
# OAuth-based authentication flow

module API
  class OauthAdapter

      attr_reader :token

      ##
      # Initialize the adapter for a grape request environment
      def initialize env
        @context = env

        # Recover token once for scope of request
        @token = authenticate!
      end

      ##
      # Return the grape API endpoint from current context
      def endpoint
        @context['api.endpoint']
      end

      ##
      # We store route oauth parameters as a route_setting with the key 'oauth'
      def options
        endpoint.route_setting(:oauth)
      end

      ##
      # Convert Grape handled request to an ActionDispatch::Request
      def doorkeeper_formatted_request
        ActionDispatch::Request.new(@context)
      end


      ##
      # Pass the current request as an ActionDispatch::Request to doorkeeper
      # to possibly recover an access token from the defined token methods.
      #
      # Test the returned token (if any) against the route scopes defined in the grape api endpoint.
      # Returns true iff the doorkeeper token is fresh and valid for the requested route.
      def authenticated?
        if @token
          @token.acceptable?(*route_scopes)
        else
          false
        end
      end

      ##
      # Test whether this route needs oauth token authentication
      def route_protected?
        !!options[:disable_auth]
      end

      ##
      # Reads all defined scope for the current api endpoint
      def route_scopes
        options[:scopes] || Doorkeeper.configuration.default_scopes
      end

      private

      ##
      # Recover the oauth token from the api request and returns
      # the authentication status.
      def authenticate!
        Doorkeeper.authenticate(doorkeeper_formatted_request, Doorkeeper.configuration.access_token_methods)
      end

  end
end
