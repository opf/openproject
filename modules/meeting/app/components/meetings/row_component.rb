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

module Meetings
  class RowComponent < ::RowComponent
    def project_name
      helpers.link_to_project model.project, {}, {}, false
    end

    def title
      link_to model.title, project_meeting_path(model.project, model)
    end

    def type
      if model.is_a?(StructuredMeeting)
        I18n.t("meeting.types.structured")
      else
        I18n.t("meeting.types.classic")
      end
    end

    def start_time
      safe_join([helpers.format_date(model.start_time), helpers.format_time(model.start_time, false)], " ")
    end

    def duration
      "#{number_with_delimiter model.duration} h"
    end

    def location
      helpers.auto_link(model.location,
                        link: :all,
                        html: { target: "_blank" })
    end
  end
end
