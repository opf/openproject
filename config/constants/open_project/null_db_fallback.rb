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
  module NullDbFallback
    class << self
      def fallback
        ActiveRecord::Base.connection.execute("SELECT 1")
      rescue ActiveRecord::NoDatabaseError => e
        Rails.logger.error "Database connection could not be established: #{e}. Falling back to NullDB."
        applied!
        ActiveRecord::Base.establish_connection adapter: :nulldb
      end

      # Reconnects to the real database once it is available, e.g. after
      # +db:create+ has created the database this process failed to reach when
      # it booted. Resolving the connection through the environment name rather
      # than config/database.yml keeps DATABASE_URL working.
      def reset
        return unless applied?

        # Only drop the flag once the reconnect went through: a process that
        # failed to leave NullDB has to stay eligible for a later retry.
        ActiveRecord::Base.establish_connection(Rails.env.to_sym)
        unapplied!
      end

      private

      attr_accessor :applied

      def applied!
        self.applied = true
      end

      def unapplied!
        self.applied = false
      end

      def applied?
        !!applied
      end
    end
  end
end
