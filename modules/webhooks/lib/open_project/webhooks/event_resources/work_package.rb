# frozen_string_literal: true

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

require_relative "base"

module OpenProject::Webhooks::EventResources
  class WorkPackage < Base
    class << self
      def notification_names
        [
          OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
        ]
      end

      def available_actions
        %i(updated created)
      end

      def resource_name
        I18n.t :label_work_package_plural
      end

      protected

      def handle_notification(payload, event_name)
        journal = payload[:journal]
        action = journal.initial? ? "created" : "updated"
        event_name = prefixed_event_name(action)
        work_package = journal.journable
        actor = User.find_by(id: journal.user_id)
        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          WorkPackageWebhookJob.perform_later(id, work_package, event_name, actor:)
        end
      end
    end
  end
end
