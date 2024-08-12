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
  module HealthChecks
    class PumaCheck < OkComputer::Check
      attr_reader :threshold

      def initialize(threshold = OpenProject::Configuration.health_checks_backlog_threshold)
        @threshold = threshold.to_i
        @applicable = Object.const_defined?("Puma::Server") && !Puma::Server.current.nil?
        super()
      end

      def check
        stats = self.stats

        return mark_message "N/A as Puma is not used." if stats.nil?

        if stats[:running] > 0
          mark_message "Puma is running"
        else
          mark_failure
          mark_message "Puma is not running"
        end

        if stats[:backlog] < threshold
          mark_message "Backlog ok"
        else
          mark_failure
          mark_message "Backlog congested"
        end
      end

      def stats
        return nil unless applicable?

        server = Puma::Server.current
        return nil if server.nil?

        {
          backlog: server.backlog || 0,
          running: server.running || 0,
          pool_capacity: server.pool_capacity || 0,
          max_threads: server.max_threads || 0
        }
      end

      def applicable?
        !!@applicable
      end
    end
  end
end
