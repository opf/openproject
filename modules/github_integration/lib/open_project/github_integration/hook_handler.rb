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

module OpenProject::GithubIntegration
  class HookHandler
    # List of the github events we can handle.
    KNOWN_EVENTS = %w[
      check_run
      issue_comment
      ping
      pull_request
    ].freeze

    # A github webhook happened.
    # We need to check validity of the data and send a Notification
    # to be processed in our `NotificationHandler`.
    def process(_hook, request, params, user)
      event_type = request.env["HTTP_X_GITHUB_EVENT"]
      event_delivery = request.env["HTTP_X_GITHUB_DELIVERY"]

      Rails.logger.debug { "Received github webhook #{event_type} (#{event_delivery})" }

      return 404 unless valid_event?(event_type, event_delivery)
      return 403 unless authorized?(request, user)

      notify(params, user, event_type, event_delivery)
      200
    end

    private

    def valid_event?(event_type, event_delivery)
      KNOWN_EVENTS.include?(event_type) && event_delivery
    end

    def authorized?(request, user)
      valid_signature?(request) &&
        user.present? &&
        (configured_user_id.blank? || user.id == configured_user_id)
    end

    def notify(params, user, event_type, event_delivery)
      payload = params[:payload]
                .permit!
                .to_h
                .merge("open_project_user_id" => user.id,
                       "github_event" => event_type,
                       "github_delivery" => event_delivery)

      OpenProject::Notifications.send("github.#{event_type}", payload)
    end

    def valid_signature?(request)
      secret = plugin_settings[:webhook_secret].presence
      return true if secret.blank?

      signature_header = request.env["HTTP_X_HUB_SIGNATURE_256"]
      return false if signature_header.blank?

      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, request.raw_post)}"
      ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
    end

    def configured_user_id
      plugin_settings[:github_user_id].presence&.to_i
    end

    def plugin_settings
      Hash(Setting.plugin_openproject_github_integration).with_indifferent_access
    end
  end
end
