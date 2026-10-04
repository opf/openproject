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

module Meetings::PDF::Default
  class Exporter < ::Meetings::PDF::Common::Exporter
    include Exports::PDF::Common::Badge
    include Exports::PDF::Components::Cover
    include Meetings::PDF::Default::Styles
    include Meetings::PDF::Default::PageHead
    include Meetings::PDF::Default::Participants
    include Meetings::PDF::Default::Agenda
    include Meetings::PDF::Default::Attachments

    def render_doc
      write_cover_page! if with_cover?
      render_meeting!
    end

    def render_meeting!
      write_page_head
      write_participants if with_participants?
      write_agenda
      write_attachments_list if with_attachments_list?
      write_backlog if with_backlog?
      write_headers!
      write_footers!
    end

    def write_hr
      hr_style = styles.heading_hr
      with_vertical_margin(styles.heading_hr_margins) do
        write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
      end
    end

    def footer_title
      options[:footer_text] || project_title
    end

    def with_participants?
      ActiveModel::Type::Boolean.new.cast(options[:participants])
    end

    def with_attachments_list?
      ActiveModel::Type::Boolean.new.cast(options[:attachments])
    end

    def with_backlog?
      ActiveModel::Type::Boolean.new.cast(options[:backlog])
    end

    def with_cover?
      true
    end
  end
end
