# frozen_string_literal: true

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

module Repositories::Gitlab
  class HookHandler
    # List of the gitlab events we can handle.
    KNOWN_EVENTS = %w[
      push
      issue
      note
      merge_request
      pipeline
    ].freeze

    # A gitlab webhook happened.
    # We need to check validity of the data and send a Notification
    # which we process in our NotificationHandler.
    def process(_hook, request, params, user)
      event_type = params[:event_type] || params[:event_name] || params[:object_kind]

      Rails.logger.debug { "Received gitlab webhook #{event_type}" }

      return 404 unless KNOWN_EVENTS.include?(event_type)

      provider = find_provider(params)
      return 404 if provider.nil?
      return 403 unless authorized?(request, user, provider)

      notify(params, user, provider, event_type)
      200
    end

    private

    def find_provider(params)
      ::Repositories::GitlabProvider.for_web_url(params.dig(:payload, :project, :web_url))
    end

    def authorized?(request, user, provider)
      valid_token?(request, provider) &&
        user.present? &&
        (provider.gitlab_user_id.blank? || user.id == provider.gitlab_user_id)
    end

    def notify(params, user, provider, event_type)
      payload = params[:payload]
                .permit!
                .to_h
                .merge("open_project_user_id" => user.id, "repository_provider_id" => provider.id)

      OpenProject::Notifications.send(:"gitlab.#{event_type}_hook", payload)
    end

    def valid_token?(request, provider)
      secret = provider.webhook_secret.presence
      return true if secret.blank?

      token_header = request.env["HTTP_X_GITLAB_TOKEN"]
      return false if token_header.blank?

      ActiveSupport::SecurityUtils.secure_compare(secret, token_header)
    end
  end
end
