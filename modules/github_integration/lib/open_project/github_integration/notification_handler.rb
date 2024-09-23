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

require_relative "notification_handler/helper"
require_relative "notification_handler/issue_comment"
require_relative "notification_handler/pull_request"

module OpenProject::GithubIntegration
  ##
  # Handles github-related notifications.
  # Each method is named after their webhook "event" as documented here:
  # https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads
  module NotificationHandler
    class << self
      def check_run(payload)
        with_logging do
          OpenProject::GithubIntegration::NotificationHandler::CheckRun.new.process(payload)
        end
      end

      def issue_comment(payload)
        with_logging do
          OpenProject::GithubIntegration::NotificationHandler::IssueComment.new.process(payload)
        end
      end

      def pull_request(payload)
        with_logging do
          OpenProject::GithubIntegration::NotificationHandler::PullRequest.new.process(payload)
        end
      end

      private

      def with_logging
        yield if block_given?
      rescue StandardError => e
        Rails.logger.error "Failed to handle issue_comment event: #{e} #{e.message}"
        raise e
      end
    end
  end
end
