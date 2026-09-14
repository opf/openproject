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

module Exports::PDF::Artefact::Toc
  # Fixed-width placeholder shown while the real page number is not yet known.
  # Keeps the table of contents layout stable between the two render passes.
  TOC_DUMMY_PAGE_NR = "000"

  def write_toc!
    with_margin(styles.toc_margins) do
      write_toc_heading!
      toc_entries.each { |entry| write_toc_item!(entry) }
    end
    pdf.start_new_page
  end

  private

  def write_toc_heading!
    style = styles.toc_heading
    with_margin(styles.toc_heading_margins) do
      pdf.formatted_text([style.merge({ text: I18n.t(:label_table_of_contents) })], style)
    end
  end

  def write_toc_item!(entry)
    style = styles.toc_item
    page_nr = (entry[:page_number] || TOC_DUMMY_PAGE_NR).to_s
    with_margin(styles.toc_item_margins) do
      y_start = pdf.y
      write_toc_item_page_nr!(page_nr, style)
      write_toc_item_title!(entry[:title], measure_text_width(page_nr, style), style)
      write_toc_item_link!(entry, y_start)
    end
  end

  def write_toc_item_page_nr!(page_nr, style)
    right_style = style.merge({ align: :right })
    pdf.float { pdf.formatted_text([right_style.merge({ text: page_nr })], right_style) }
  end

  def write_toc_item_title!(title, page_nr_width, style)
    pdf.indent(0, page_nr_width) do
      pdf.formatted_text([style.merge({ text: title })], style)
    end
  end

  def write_toc_item_link!(entry, y_start)
    rect = [pdf.bounds.absolute_right, pdf.y, pdf.bounds.absolute_left, y_start]
    pdf.link_annotation(rect, Border: [0, 0, 0], Dest: entry[:id].to_s)
  end
end
