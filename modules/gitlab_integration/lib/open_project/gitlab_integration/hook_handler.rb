#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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

module OpenProject::GitlabIntegration
  class HookHandler
    # List of the gitlab events we can handle.
    KNOWN_EVENTS = %w[
      push_hook
      issue_hook
      note_hook
      merge_request_hook
      pipeline_hook
      system_hook
    ].freeze

    # A gitlab webhook happened.
    # We need to check validity of the data and send a Notification
    # which we process in our NotificationHandler.
    def process(_hook, request, params, user)
      event_type = normalize_event_type(request)

      Rails.logger.debug { "Received gitlab webhook #{event_type}" }

      return 404 unless KNOWN_EVENTS.include?(event_type)
      return 403 unless authorized?(request, user)

      notify(params, user, event_type)
      200
    end

    private

    def normalize_event_type(request)
      request.env["HTTP_X_GITLAB_EVENT"].tr(" ", "_").downcase
    end

    def authorized?(request, user)
      valid_token?(request) &&
        user.present? &&
        (configured_user_id.blank? || user.id == configured_user_id)
    end

    def notify(params, user, event_type)
      payload = params[:payload]
                .permit!
                .to_h
                .merge("open_project_user_id" => user.id,
                       "gitlab_event" => event_type)

      OpenProject::Notifications.send(:"gitlab.#{event_type}", payload)
    end

    def valid_token?(request)
      secret = plugin_settings[:webhook_secret].presence
      return true if secret.blank?

      token_header = request.env["HTTP_X_GITLAB_TOKEN"]
      return false if token_header.blank?

      ActiveSupport::SecurityUtils.secure_compare(secret, token_header)
    end

    def configured_user_id
      plugin_settings[:gitlab_user_id].presence&.to_i
    end

    def plugin_settings
      Hash(Setting.plugin_openproject_gitlab_integration).with_indifferent_access
    end
  end
end
