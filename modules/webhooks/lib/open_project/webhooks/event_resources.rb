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

module OpenProject::Webhooks
  module EventResources
    class << self
      def subscribe!
        resource_modules.each(&:subscribe!)
      end

      ##
      # Return a complete mapping of all resource modules
      # in the form { label => { event1: label , event2: label } }
      def available_events_map
        resource_modules.to_h { |m| [m.resource_name, m.available_events_map] }
      end

      ##
      # Find a module based on the event name
      def lookup_resource_name(event_name)
        resource, events = available_events_map.detect { |_, events_map| events_map.key?(event_name) }
        event = events[event_name] if resource

        [resource, event]
      end

      def resource_modules
        @resource_modules ||= resources.map do |name|
          require_relative "./event_resources/#{name}"
          "OpenProject::Webhooks::EventResources::#{name.to_s.camelize}".constantize
        rescue LoadError, NameError => e
          raise ArgumentError, "Failed to initialize resources module for #{name}: #{e}"
        end
      end

      def resources
        %i(project work_package work_package_comment time_entry attachment)
      end
    end
  end
end
