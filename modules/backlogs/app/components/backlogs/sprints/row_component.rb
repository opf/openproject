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

module Backlogs
  module Sprints
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      include Redmine::I18n
      include Backlogs::SprintsHelper

      delegate :project, to: :table
      alias_method :sprint, :model

      def name
        if (href = href_for_sprint(sprint, project))
          render(Primer::Beta::Link.new(href:, font_weight: :bold)) { sprint.name }
        else
          sprint.name
        end
      end

      def status
        render(SprintStatusBadgeComponent.new(sprint:))
      end

      def start_date
        format_date(sprint.start_date) if sprint.start_date
      end

      def finish_date
        format_date(sprint.finish_date) if sprint.finish_date
      end

      def work_package_count
        table.work_package_counts.fetch(sprint.id, 0)
      end

      def row_css_id
        dom_id(sprint)
      end
    end
  end
end
