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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "base"

module OpenProject::Webhooks::EventResources
  class Attachment < Base
    class << self
      def notification_names
        [
          OpenProject::Events::ATTACHMENT_CREATED
        ]
      end

      def available_actions
        %i(created)
      end

      def resource_name
        I18n.t :"attributes.attachments"
      end

      protected

      def handle_notification(payload, event_name)
        action = event_name.split("_").last
        event_name = prefixed_event_name(action)

        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          AttachmentWebhookJob.perform_later(id, payload[:attachment], event_name)
        end
      end
    end
  end
end
