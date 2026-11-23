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

module Exports::PDF::Common::Text
  ELLIPSIS = "..."
  LINE_HEIGHT_TOLERANCE = 0.01
  FALLBACK_CAP_HEIGHT_RATIO = 0.7

  def paint_fitted_text(text, left, top, width, height, size:, max_lines:, style: :normal, align: :left)
    font_options = { size:, style:, leading: 0 }
    lines = fit_lines(text, width, height, max_lines, font_options)
    return if lines.empty?

    @pdf.text_box(lines.join("\n"),
                  at: [@pdf.bounds.left + left, @pdf.bounds.top - top - optical_top_offset(lines.size, height, size)],
                  width:,
                  height: lines_height(lines.size, size),
                  overflow: :truncate,
                  align:,
                  **font_options)
  end

  def fit_lines(text, width, height, max_lines, font_options)
    box = fitting_text_box(text, width, height, max_lines, font_options)
    remaining = box.render(dry_run: true)
    lines = box.text.split("\n")
    lines[-1] = ellipsize(text_from_last_line(text, lines), width, font_options) if remaining.present? && lines.any?
    lines
  end

  def optical_top_offset(line_count, height, size)
    ascender, descender, cap_height = font_metrics(size)
    ink_height = cap_height + ((line_count - 1) * @pdf.font.height_at(size)) + (descender / 2)
    ((height - ink_height) / 2) - (ascender - cap_height)
  end

  def font_metrics(size)
    font = @pdf.font
    scale = size / @pdf.font_size.to_f
    [font.ascender * scale, font.descender * scale, cap_height_ratio(font) * size]
  end

  def cap_height_ratio(font)
    return FALLBACK_CAP_HEIGHT_RATIO unless font.respond_to?(:ttf) && font.ttf.os2.exists?

    cap_height = font.ttf.os2.cap_height.to_f
    cap_height.positive? ? cap_height / font.ttf.header.units_per_em : FALLBACK_CAP_HEIGHT_RATIO
  end

  # Prawn wraps at word boundaries; the ellipsized last line continues with the rest of the text,
  # so it can be cut within a word and fill the available width.
  def text_from_last_line(text, lines)
    position = lines[0..-2].inject(0) do |offset, line|
      (text.index(line, offset) || offset) + line.length
    end
    start = text.index(lines.last, position) || position
    text[start..].tr("\n", " ")
  end

  def fitting_text_box(text, width, height, max_lines, font_options)
    line_height = @pdf.font.height_at(font_options[:size])
    line_count = [max_lines, (height / line_height).floor].min.clamp(1..)
    Prawn::Text::Box.new(text, document: @pdf, width:, overflow: :truncate,
                               height: lines_height(line_count, font_options[:size]), **font_options)
  end

  def lines_height(line_count, size)
    (line_count * @pdf.font.height_at(size)) + LINE_HEIGHT_TOLERANCE
  end

  def ellipsize(text, available_width, font_options)
    fits = ->(length) { @pdf.width_of("#{text[0, length].rstrip}#{ELLIPSIS}", font_options) <= available_width }
    length = (0..text.length).bsearch { |candidate| !fits.call(candidate) } || (text.length + 1)
    "#{text[0, length - 1].to_s.rstrip}#{ELLIPSIS}"
  end
end
