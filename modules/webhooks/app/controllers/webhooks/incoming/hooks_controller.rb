#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require 'json'

module Webhooks
  module Incoming
    class HooksController < ApplicationController
      accept_key_auth :handle_hook

      # Disable CSRF detection since we openly welcome POSTs here!
      skip_before_action :verify_authenticity_token

      # Wrap the JSON body as 'payload' param
      # making it available as params[:payload]
      wrap_parameters :payload

      def api_request?
        # OpenProject only allows API requests based on an Accept request header.
        # Webhooks (at least GitHub) don't send an Accept header as they're not interested
        # in any part of the response except the HTTP status code.
        # Also handling requests with a application/json Content-Type as API requests
        # should be safe regarding CSRF as browsers don't send forms as JSON.
        super || request.content_type == "application/json"
      end

      def handle_hook
        hook = OpenProject::Webhooks.find(params.require 'hook_name')

        if hook
          code = hook.handle(request, params, find_current_user)
          head code.is_a?(Integer) ? code : 200
        else
          head :not_found
        end
      end
    end
  end
end
