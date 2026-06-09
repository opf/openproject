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

module OpPrimer
  # @logical_path OpenProject/Primer
  class QuickFilterPreview < Lookbook::Preview
    def segmented_control
      render_with_template(locals: { query: meeting_query })
    end

    def segmented_control_with_active_filter
      query = meeting_query
      query.where("time", "=", ["future"])
      render_with_template(locals: { query: })
    end

    def boolean
      query = meeting_query
      query.where("type", "=", ["t"])
      render_with_template(locals: { query: })
    end

    def select_panel_with_active_filter
      query = meeting_query
      query.where("project_id", "=", [Project.visible.first&.id.to_s].compact)
      render_with_template(locals: { query: })
    end

    private

    def meeting_query
      Queries::Meetings::MeetingQuery.new(user: User.current)
    end
  end
end
