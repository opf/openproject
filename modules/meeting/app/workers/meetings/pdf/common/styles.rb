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

module Meetings::PDF::Common::Styles
  class Base
    include MarkdownToPDF::Common
    include MarkdownToPDF::StyleHelper
    include Exports::PDF::Common::Styles
    include Exports::PDF::Components::PageStyles
    include Exports::PDF::Components::CoverStyles

    def page_subtitle
      resolve_font(@styles[:page_subtitle])
    end

    def page_subtitle_margins
      resolve_margin(@styles[:page_subtitle])
    end

    def notes_markdown_margins
      resolve_margin(@styles.dig(:notes, :markdown_margin))
    end

    def notes_markdown_styling_yml
      resolve_markdown_styling(@styles.dig(:notes, :markdown) || {})
    end

    def outcome_markdown_styling_yml
      resolve_markdown_styling(@styles.dig(:outcome, :markdown) || {})
    end

    def heading
      resolve_font(@styles[:heading])
    end

    def heading_margins
      resolve_margin(@styles[:heading])
    end

    def agenda_item_title_margins
      resolve_margin(@styles.dig(:agenda_item, :title_margin))
    end

    def agenda_item_indent
      @styles.dig(:agenda_item, :indent).presence || 5
    end

    def outcome_title
      resolve_font(@styles.dig(:outcome, :title))
    end

    def outcome_symbol
      resolve_font(@styles.dig(:outcome, :symbol))
    end

    def outcome_title_margins
      resolve_margin(@styles.dig(:outcome, :title))
    end

    def outcome_markdown_margins
      resolve_margin(@styles.dig(:outcome, :markdown_margin))
    end

    def outcome_indent
      @styles.dig(:outcome, :indent).presence || 15
    end

    def outcome_work_package
      resolve_font(@styles.dig(:outcome, :work_package))
    end

    def outcome_work_package_margin
      resolve_margin(@styles.dig(:outcome, :work_package))
    end

    def agenda_item_title
      resolve_font(@styles.dig(:agenda_item, :title))
    end

    def agenda_item_title_cell
      resolve_table_cell(@styles.dig(:agenda_item, :title_cell))
    end

    def agenda_item_subtitle
      resolve_font(@styles.dig(:agenda_item, :subtitle))
    end

    def participants_table_cell
      resolve_table_cell(@styles.dig(:participants, :cell))
    end

    def participants_status
      resolve_font(@styles.dig(:participants, :status))
    end

    def participants_margins
      resolve_margin(@styles[:participants])
    end

    def attachments_table_cell
      resolve_table_cell(@styles.dig(:attachments, :cell))
    end

    def attachments_margins
      resolve_margin(@styles[:attachments])
    end

    def agenda_section_title
      resolve_font(@styles.dig(:agenda_section, :title))
    end

    def agenda_section_title_table_margins
      resolve_margin(@styles.dig(:agenda_section, :title_margins))
    end

    def agenda_section_subtitle
      resolve_font(@styles.dig(:agenda_section, :subtitle))
    end

    def agenda_section_title_cell
      resolve_table_cell(@styles.dig(:agenda_section, :title_cell))
    end
  end
end
