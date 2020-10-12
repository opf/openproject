#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  ##
  # Notifications about Events in OpenProject (e.g. created work packages)
  #
  # @see OpenProject::Events
  module Notifications
    module_function

    # Subscribe to a specific event with name
    # Contrary to ActiveSupport::Notifications, we don't support regexps here, but only
    # single events specified as string.
    #
    # @param name [String] The name of the event to subscribe to.
    # @param clear_subscriptions [Boolean] Clears all previous subscriptions to this
    #                                      event if true. Use with care!
    # @return [Int] Subscription ID
    # @raises ArgumentError if no block is given.
    def subscribe(name, clear_subscriptions: false, &block)
      # if no block is given, raise an error
      raise ArgumentError, 'please provide a block as a callback' unless block_given?

      if clear_subscriptions
        subscriptions[name].each do |sub|
          ActiveSupport::Notifications.unsubscribe sub
        end
      end

      sub = ActiveSupport::Notifications.subscribe(name.to_s) do |_, _, _, _, payload|
        block.call(payload)
      end

      subs = clear_subscriptions ? [] : Array(subscriptions[name])
      subscriptions[name] = subs + [sub]

      subscriptions[name].size - 1
    end

    def unsubscribe(name, id)
      sub = subscriptions[name].delete_at id

      if sub
        ActiveSupport::Notifications.unsubscribe sub

        true
      end
    end

    # Send a notification
    # payload should be a Hash and might be marshalled and unmarshalled before being
    # delivered (although it is not at the moment), so don't count on object equality
    # for the payload.
    def send(name, payload)
      ActiveSupport::Notifications.instrument(name.to_s, payload)
    end

    def subscriptions
      @subscriptions ||= {}
    end
  end
end
