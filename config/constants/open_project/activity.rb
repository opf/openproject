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
  module Activity
    class << self
      def available_event_types
        @available_event_types ||= Set.new
      end

      def default_event_types
        @default_event_types ||= Set.new
      end

      def providers
        @providers ||= Hash.new { |h, k| h[k] = Set.new }
      end

      def map(&)
        yield self
      end

      # Registers an activity provider
      def register(event_type, options = {})
        options.assert_valid_keys(:class_name, :default)

        event_type = event_type.to_s
        available_event_types << event_type
        default_event_types << event_type unless options[:default] == false

        providers = options[:class_name] || event_type.classify
        self.providers[event_type] += Array(providers)
      end
    end
  end
end
