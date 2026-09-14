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
  module TokenBucketBasedRateLimiter
    # Abstract class. Sub classes need to provide the upper limit of the bucket by implementing the `identifier` and
    # `limit` instance methods.
    class Base
      MICROTOKENS_PER_TOKEN = 1_000_000
      SECONDS_PER_DAY = 24 * 60 * 60

      class NotImplemented < StandardError; end

      def self.consume!(tokens = 1)
        new.consume!(tokens)
      end

      def self.enabled?
        new.enabled?
      end

      def self.limit
        new.limit
      end

      def consume!(tokens = 1)
        return true unless enabled?

        now = Time.current
        required_microtokens = tokens * MICROTOKENS_PER_TOKEN

        TokenBucketState.with_instance(identifier) do |state|
          available_microtokens = available_microtokens(state, now)

          if available_microtokens >= required_microtokens
            state.update!(
              microtokens: available_microtokens - required_microtokens,
              refilled_at: now
            )

            true
          else
            false
          end
        end
      end

      def enabled?
        limit.positive?
      end

      # Maximum number of tokens (not microtokens) the bucket can hold.
      def limit
        raise NotImplemented, "Subclass responsibility"
      end

      private

      # String used to identify the TokenBucketState instance which stores the number of available (micro) tokens.
      def identifier
        raise NotImplemented, "Subclass responsibility"
      end

      # Maximum number of microtokens the bucket can hold.
      def capacity
        @capacity ||= limit * MICROTOKENS_PER_TOKEN
      end

      # Number of microtokens, which should be added per second
      #
      # The default implementation assumes that `limit` is a daily limit, i.e. the refill rate is based on the number of
      # seconds per day.  When implementing e.g. an hourly limit, then this method needs to be overwritten in a subclass
      # to adjust the calculation accordingly.
      def refill_rate
        @refill_rate ||= capacity.to_f / SECONDS_PER_DAY
      end

      def available_microtokens(state, now)
        seconds_since_last_refill = [now - state.refilled_at, 0].max

        [
          state.microtokens + (seconds_since_last_refill * refill_rate).floor,
          capacity
        ].min
      end
    end
  end
end
