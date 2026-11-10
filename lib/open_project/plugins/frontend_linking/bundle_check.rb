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

require "json"

module ::OpenProject::Plugins
  module FrontendLinking
    class BundleCheck
      LINKED_ENTRY = %r{plugins/linked/([^/]+)/main\.ts\z}

      attr_reader :stats_path, :expected

      def initialize(stats_path, expected:)
        @stats_path = stats_path
        @expected = expected
      end

      def verify!
        missing = expected - bundled_plugin_names
        return if missing.empty?

        raise "Frontend plugins missing from the compiled bundle: #{missing.sort.join(', ')}"
      end

      private

      def bundled_plugin_names
        JSON.parse(File.read(stats_path))
          .fetch("outputs")
          .values
          .flat_map { |output| output.fetch("inputs", {}).select { |_, input| input["bytesInOutput"].positive? }.keys }
          .filter_map { |path| path[LINKED_ENTRY, 1] }
          .uniq
      end
    end
  end
end
