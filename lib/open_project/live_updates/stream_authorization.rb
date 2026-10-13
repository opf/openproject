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

module OpenProject
  module LiveUpdates
    # Included into Turbo::StreamsChannel, which anycable-go hands to Rails over RPC (`turbo = false`),
    # so that holding a signed stream name alone no longer grants the subscription.
    # Granted subscriptions are recorded, so that Cron::ReauthorizeLiveUpdatesJob can check them again.
    module StreamAuthorization
      extend ActiveSupport::Concern

      included do
        before_subscribe :authorize_live_updates_stream!
        after_subscribe :add_live_updates_subscription, unless: :subscription_rejected?
        after_unsubscribe :remove_live_updates_subscription, unless: :subscription_rejected?
      end

      private

      def authorize_live_updates_stream!
        return if OpenProject::LiveUpdates.allowed?(verified_stream_name_from_params, current_user)

        reject
        throw :abort
      end

      def add_live_updates_subscription
        LiveUpdatesSubscription.create!(user: current_user,
                                        session_id: connection.session_private_id,
                                        stream_name: verified_stream_name_from_params)
      end

      # Other tabs of the session may be subscribed to the same stream, each with its own row.
      def remove_live_updates_subscription
        LiveUpdatesSubscription.where(user: current_user,
                                      session_id: connection.session_private_id,
                                      stream_name: verified_stream_name_from_params)
                               .limit(1)
                               .delete_all
      end
    end
  end
end
