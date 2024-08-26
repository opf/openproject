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

require_relative "notification_handler/helper"
require_relative "notification_handler/issue_hook"
require_relative "notification_handler/merge_request_hook"
require_relative "notification_handler/note_hook"
require_relative "notification_handler/push_hook"
require_relative "notification_handler/system_hook"

module OpenProject::GitlabIntegration
  ##
  # Handles gitlab-related notifications.
  module NotificationHandlers
    class << self
      def merge_request_hook(payload)
        with_logging("merge_request_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::MergeRequestHook.new.process(payload)
        end
      end

      def note_hook(payload)
        with_logging("note_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::NoteHook.new.process(payload)
        end
      end

      def push_hook(payload)
        with_logging("push_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::PushHook.new.process(payload)
        end
      end

      def issue_hook(payload)
        with_logging("issue_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::IssueHook.new.process(payload)
        end
      end

      def pipeline_hook(payload)
        with_logging("pipeline_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::PipelineHook.new.process(payload)
        end
      end

      def system_hook(payload)
        with_logging("system_hook") do
          OpenProject::GitlabIntegration::NotificationHandler::SystemHook.new.process(payload)
        end
      end

      private

      def with_logging(event_hook)
        yield if block_given?
      rescue StandardError => e
        Rails.logger.error "Failed to handle #{event_hook} from Gitlab: #{e} #{e.message}"
        raise e
      end
    end
  end
end
