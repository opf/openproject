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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  module Timer
    class MenuSectionComponent < ApplicationComponent
      CHANGED_EVENT = "op-dispatched:time-entries:timer-changed"

      options :time_entry

      def render?
        time_entry.present?
      end

      private

      def work_package
        time_entry.entity
      end

      def entity_name
        "#{work_package.formatted_id}: #{work_package.subject}"
      end

      def ongoing_timer_payload
        {
          id: time_entry.id.to_s,
          createdAt: time_entry.created_at.iso8601,
          entityId: work_package.id.to_s,
          entityName: entity_name
        }.to_json
      end
    end
  end
end
