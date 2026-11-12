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

module Meetings::PDF::Common
  class Exporter < ::Exports::Exporter
    include Exports::PDF::Common::Common
    include Exports::PDF::Common::Logo
    include Exports::PDF::Common::Markdown
    include Exports::PDF::Common::Attachments
    include Exports::PDF::Common::Macro
    include Exports::PDF::Components::Page

    self.model = Meeting

    alias :meeting :object

    attr_accessor :pdf

    def self.key
      :pdf
    end

    def initialize(meeting, options)
      super(meeting, options[:options] || options)
      @total_page_nr = nil
      @page_count = 0

      setup_page!
    end

    def export!
      render_doc
      success(pdf.render)
    rescue StandardError => e
      error(e)
    ensure
      delete_all_resized_images
    end

    def setup_page!
      self.pdf = get_pdf
      pdf.title = heading
      configure_page_size!(:portrait)
    end

    def write_heading(text)
      style = styles.heading
      with_vertical_margin(styles.heading_margins) do
        pdf.formatted_text([style.merge({ text: })], style)
      end
    end

    def cover_page_title
      project_title
    end

    def cover_page_heading
      meeting.title
    end

    def cover_page_dates
      [
        "#{meeting_mode},",
        "#{format_date(meeting.start_time)},",
        format_time(meeting.start_time, include_date: false),
        "–",
        format_time(meeting.end_time, include_date: false)
      ].join(" ")
    end

    def meeting_mode
      meeting.state == "open" ? I18n.t("label_meeting_agenda") : I18n.t("label_meeting_minutes")
    end

    def cover_page_subheading
      meeting.location
    end

    def heading
      meeting.title
    end

    def project_title
      meeting.project&.name || ""
    end

    def title_datetime
      meeting.start_time.strftime("%Y-%m-%d")
    end

    def title
      build_pdf_filename(meeting.title)
    end

    def with_outcomes?
      ActiveModel::Type::Boolean.new.cast(options[:outcomes])
    end

    def with_images?
      true
    end
  end
end
