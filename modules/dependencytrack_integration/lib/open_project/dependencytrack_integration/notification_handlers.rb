#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2021 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require_relative './notification_handler/helper'
require_relative './notification_handler/new_alert'

module OpenProject::DependencytrackIntegration

  ##
  # Handles dependencytrack-related notifications.
  module NotificationHandlers
    class << self
      def new_alert(payload)
        with_logging('new_alert') do
          OpenProject::DependencytrackIntegration::NotificationHandler::NewAlert.new.process(payload)
        end
      end

      private

      def with_logging(event_hook)
        yield if block_given?
      rescue StandardError => e
        Rails.logger.error "Failed to handle #{event_hook} from DependencyTrack: #{e} #{e.message}"
        raise e
      end
    end
  end
end
