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

module OpenProject::Webhooks::EventResources
  class Base
    class << self
      ##
      # Subscribe for events on this resource schedule the respective
      # webhooks, if any.
      def subscribe!
        notification_names.each do |key|
          OpenProject::Notifications.subscribe(key) do |payload|
            Rails.logger.debug { "[Webhooks Plugin] Handling notification for '#{key}'." }
            handle_notification(payload, key)
          rescue StandardError => e
            Rails.logger.error { "[Webhooks Plugin] Failed notification handling for '#{key}': #{e}" }
          end
        end
      end

      ##
      # Return a mapping of event key to its localized name
      def available_events_map
        available_actions.map { |symbol| [prefixed_event_name(symbol), localize_event_name(symbol)] }.to_h
      end

      ##
      # Get the prefix key for this module
      def prefix_key
        name.demodulize.underscore
      end

      ##
      # Create a prefixed event name
      def prefixed_event_name(action)
        "#{prefix_key}:#{action}"
      end

      def available_actions
        raise SubclassResponsibilityError
      end

      ##
      # Localize the given event name
      def localize_event_name(key)
        I18n.t(key, scope: "webhooks.outgoing.events")
      end

      ##
      # Get the name of this resource
      def resource_name
        raise SubclassResponsibilityError
      end

      ##
      # Get the subscriptions for OP::Notifications
      def notification_names
        raise SubclassResponsibilityError
      end

      protected

      ##
      # Callback for OP::Notification
      def handle_notification(payload, event_name)
        raise NotImplementedError
      end

      ##
      # Base scope for active webhooks, helper for subclasses
      def active_webhooks
        ::Webhooks::Webhook.where(enabled: true)
      end

      def enqueue_kubernetes_scripts(event_name, project_id, payload_job_class, resource, actor: nil,
                                     triggered_by: actor || User.current)
        # Changes made through a script's own API token must not trigger scripts again (endless loops).
        return if project_id.nil? || script_service_account?(triggered_by)

        ::Webhooks::KubernetesScript.for_event(event_name, project_id).find_each do |script|
          run = ::Webhooks::KubernetesScriptRun.create!(kubernetes_script: script, project_id:, event_name:)
          ::KubernetesScriptJob.perform_later(run.id, payload_job_class.name, resource, actor:)
        end
      end

      def script_service_account?(user)
        user.is_a?(::ServiceAccount) &&
          ::ServiceAccountAssociation.exists?(service_account_id: user.id,
                                              service_type: ::Webhooks::KubernetesProjectScript.name)
      end
    end
  end
end
