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

module Exports::PDF::Artefact::Cover
  def write_cover_page!
    write_cover_logo
    write_cover_heading unless cover_page_heading.nil?
    write_cover_title unless cover_page_title.nil?
    write_cover_footers unless cover_page_footers.empty?
    pdf.start_new_page
  end

  def cover_page_heading
    nil
  end

  def cover_page_title
    nil
  end

  def cover_page_footers
    []
  end

  def write_cover_heading
    prawn_draw_text_box(
      [styles.cover_heading.merge({ text: cover_page_heading })],
      styles.cover_heading,
      styles.cover_heading_margin,
      styles.cover_heading_padding,
      styles.cover_heading_border
    )
  end

  private

  def write_cover_title
    prawn_draw_text_box(
      [styles.cover_title.merge({ text: cover_page_title })],
      styles.cover_title,
      styles.cover_title_margin,
      styles.cover_title_padding,
      styles.cover_title_border
    )
  end

  def write_cover_footers
    margins = styles.cover_footer_margin
    draw_header_text_multilines(
      cover_page_footers,
      margins[:left_margin],
      pdf.bounds.bottom + margins[:bottom_margin],
      styles.cover_footer
    )
  end

  def write_cover_logo # rubocop:disable Metrics/AbcSize
    margins = styles.cover_header_margin
    image_obj, image_info = logo_image
    height = styles.cover_header_logo_height
    scale = [height / image_info.height.to_f, 1].min
    pdf.embed_image image_obj, image_info, { at: [margins[:left_margin], pdf.bounds.top + height - margins[:top_margin]], scale: }
    image_info.width.to_f * scale
    pdf.move_down(height + margins[:top_margin] + margins[:bottom_margin])
  end
end
