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

require_relative "logging/log_delegator"

module OpenProject
  module Logging
    class << self
      ##
      # Do we use lograge in the end to perform the payload output
      def lograge_enabled?
        OpenProject::Configuration.lograge_enabled?
      end

      ##
      # The lograge class to output the payload object
      def formatter
        @formatter ||= begin
          formatter_setting = OpenProject::Configuration.lograge_formatter || "key_value"
          "Lograge::Formatters::#{formatter_setting.classify}"
            .constantize
            .new
        end
      end

      ##
      # Extend a payload to be logged with additional information
      # @param context {Hash} The context of the log, might contain controller related keys
      def extend_payload!(payload, context)
        payload_extenders.reduce(payload.dup) do |hash, handler|
          res = handler.call(context)
          hash.merge!(res) if res.is_a?(Hash)
          hash
        rescue StandardError => e
          Rails.logger.error "Failed to extend payload in #{handler.inspect}: #{e.message}"
          hash
        end
      end

      ##
      # Get a set of extenders that may add to the logging context payload
      def payload_extenders
        @payload_extenders ||= [
          method(:default_payload)
        ]
      end

      ##
      # Register a new payload extender
      # for all logging purposes
      def add_payload_extender(&block)
        payload_extenders << block
      end

      private

      def default_payload(_context)
        { user: User.current.try(:id) }
      end
    end
  end
end
