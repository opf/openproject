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

module My
  module PushSubscriptions
    class ShowPageComponent < ApplicationComponent
      include OpTurbo::Streamable

      BANNERS = {
        default: nil,
        warning: { action: :enable, label: "my_account.push_notifications.enable" },
        success: { action: :disable, label: "my_account.push_notifications.disable" },
        danger: {
          action: :retry,
          label: "my_account.push_notifications.try_again",
          aria_label: "my_account.push_notifications.try_again_label"
        }
      }.freeze

      def self.wrapper_key(_object = nil) = "my-push-subscriptions"

      def initialize(user:, current_session:)
        super()

        @user = user
        @current_session = current_session
      end

      private

      attr_reader :user, :current_session

      def subscriptions
        @subscriptions ||= ::PushSubscription.where(user:).preload(:session).order(:created_at, :id).to_a
      end

      def available? = OpenProject::WebPush.key_readable?

      def initial_state
        @initial_state ||= subscriptions.any? { bound_to_current_session?(it) } ? :enabled : :disabled
      end

      def initial_scheme = initial_state == :enabled ? :success : :warning

      def banner_visible?(scheme) = scheme == initial_scheme

      def banner_message(scheme)
        return "" unless banner_visible?(scheme)

        if initial_state == :enabled
          t("my_account.push_notifications.status.enabled")
        else
          t("my_account.push_notifications.status.disabled")
        end
      end

      def stimulus_data
        return {} unless available?

        {
          controller: "my--push-subscription",
          "my--push-subscription-vapid-public-key-value": OpenProject::WebPush.public_key,
          "my--push-subscription-create-url-value": my_push_subscriptions_path,
          "my--push-subscription-subscriptions-value": subscriptions_json,
          "my--push-subscription-messages-value": messages_json
        }
      end

      def subscriptions_json
        subscriptions
          .map { { endpoint: it.endpoint, revokeUrl: my_push_subscription_path(it), current: bound_to_current_session?(it) } }
          .to_json
      end

      def messages_json
        %i[unsupported blocked enabled disabled error prompting subscribing timeout]
          .index_with { t("my_account.push_notifications.status.#{it}") }
          .to_json
      end

      def bound_to_current_session?(subscription)
        subscription.session.current?(current_session)
      end
    end
  end
end
