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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Webhooks
  module Outgoing
    class UpdateWebhookService
      attr_reader :current_user, :webhook

      def initialize(webhook, current_user:)
        @current_user = current_user
        @webhook = webhook
      end

      def call(attributes: {})
        ::Webhooks::Webhook.transaction do
          set_attributes attributes
          raise ActiveRecord::Rollback unless webhook.errors.empty? && webhook.save
        end

        ServiceResult.new success: webhook.errors.empty?, errors: webhook.errors, result: webhook
      end

      private

      def set_attributes(params)
        set_selected_projects!(params)
        set_selected_events!(params)

        webhook.attributes = params
      end

      def set_selected_events!(params)
        events = params.delete(:events) || []
        webhook.event_names = events.select(&:present?)
      end

      def set_selected_projects!(params)
        option = params.delete :project_ids
        selected = params.delete :selected_project_ids

        if option == "all"
          webhook.all_projects = true
        else
          webhook.all_projects = false
          webhook.project_ids = selected
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        Rails.logger.error "Failed to set project association on webhook: #{e}"
        webhook.errors.add :project_ids, :invalid
      end
    end
  end
end
