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

module Meetings::PDF::Minutes
  class Exporter < ::Meetings::PDF::Common::Exporter
    include Meetings::PDF::Minutes::Styles
    include Meetings::PDF::Minutes::PageHead
    include Meetings::PDF::Minutes::Agenda

    def self.active?(template)
      (template == "minutes") && OpenProject::FeatureDecisions.minutes_styling_meeting_pdf_active?
    end

    def render_doc
      render_meeting
      render_again_with_total_page_nrs if wants_total_page_nrs?
    end

    def render_again_with_total_page_nrs
      @total_page_nr = pdf.page_count + @page_count
      @page_count = 0
      setup_page! # clear current pdf
      render_meeting
    end

    def render_meeting
      write_page_head
      write_agenda
      write_minutes_headers
      write_minutes_footers
    end

    def page_header_text
      options[:first_page_header_left] || ""
    end

    def write_minutes_headers
      write_logo!
      write_minutes_headers_text
    end

    def write_minutes_headers_text
      pdf.repeat lambda { |pg| pg == 1 }, dynamic: true do
        draw_header_text_multiline_left(
          text: page_header_text,
          text_style: styles.page_header,
          available_width: styles.page_header_width,
          top: pdf.bounds.top + styles.page_logo_height,
          max_lines: MAX_NR_OF_PDF_HEADER_LINES
        )
      end
    end

    def write_minutes_footers
      pdf.repeat lambda { |pg| header_footer_filter_pages.exclude?(pg) }, dynamic: true do
        draw_minutes_footer_on_page
        draw_footer_image
      end
    end

    def draw_minutes_footer_on_page
      top = styles.page_footer_offset
      text_style = styles.page_footer
      pos_right = draw_text_right(footer_page_nr, text_style, top)
      spacing = styles.page_footer_horizontal_spacing
      draw_footer_text_multiline_left(
        text: footer_minutes,
        text_style:,
        available_width: pdf.bounds.width - spacing - pos_right,
        top:,
        max_lines: MAX_NR_OF_PDF_FOOTER_LINES
      )
    end

    def minutes_author
      options[:author] || ""
    end

    def footer_minutes
      "#{meeting.title} • #{format_date(meeting.start_time)}"
    end

    def footer_page_nr
      if @total_page_nr
        I18n.t("meeting.export.minutes.footer_page_numbers", current_page: current_page_nr, total_pages: total_page_nr)
      else
        current_page_nr.to_s
      end
    end

    def with_cover?
      false
    end

    def wants_total_page_nrs?
      true
    end
  end
end
