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

module Projects
  module Types
    # The state of a backgrounded switch as the settings page sees it. Keyed on
    # the project rather than on the user who started it: a switch changes the
    # project for everyone, so anyone opening the page while one runs sees it.
    class SwitchStatus
      PENDING = %w[in_queue in_process].freeze

      class << self
        def pending_for(project)
          wrap(rows(project).where(status: PENDING).last)
        end

        def latest_for(project)
          wrap(rows(project).last)
        end

        private

        # Matched on the payload rather than on the polymorphic reference, which
        # carries a unique index and so cannot hold a project that is switched
        # more than once. The kind keeps other jobs' rows out.
        def rows(project)
          ::JobStatus::Status
            .where("payload->>'kind' = ? AND payload->>'project_id' = ?",
                   SwitchVariantJob::KIND, project.id.to_s)
            .order(:updated_at, :id)
        end

        def wrap(row) = row && new(row)
      end

      delegate :success?, :message, to: :@row

      def initialize(row)
        @row = row
      end

      def source_id
        @row.payload["source_id"]
      end

      def target
        return @target if defined?(@target)

        @target = ::Type.find_by(id: @row.payload["target_id"])
      end
    end
  end
end
