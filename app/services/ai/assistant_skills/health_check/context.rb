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

module AI
  module AssistantSkills
    module HealthCheck
      # The only way the rules read data. Everything goes through what the user can see,
      # so evidence never names a work package the user cannot open.
      class Context
        MAX_DESCENDANTS = 200
        STALE_AFTER = 60.days

        attr_reader :work_package, :user, :not_checked

        def initialize(work_package:, user:)
          @work_package = work_package
          @user = user
          @not_checked = []
        end

        def closed?
          work_package.closed?
        end

        def descendants
          @descendants ||= begin
            scope = work_package.descendants.visible(user).includes(:status).order(:id)
            records = scope.limit(MAX_DESCENDANTS + 1).to_a
            if records.size > MAX_DESCENDANTS
              add_not_checked(:tree, :too_many_descendants)
              records = records.first(MAX_DESCENDANTS)
            end
            records
          end
        end

        def open_descendants
          descendants.reject(&:closed?)
        end

        def stale?(record)
          record.updated_at < STALE_AFTER.ago
        end

        def add_not_checked(area, reason)
          entry = { "area" => area.to_s, "reason" => reason.to_s }
          @not_checked << entry unless @not_checked.include?(entry)
        end
      end
    end
  end
end
