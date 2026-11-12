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

module Exports::PDF::Components::PageStyles
  def page_size
    @styles[:page_size] || "A4"
  end

  def page_header_offset
    resolve_pt(@styles.dig(:page_header, :offset), 20)
  end

  def page_footer_offset
    resolve_pt(@styles.dig(:page_footer, :offset), -30)
  end

  def page_footer_horizontal_spacing
    resolve_pt(@styles.dig(:page_footer, :spacing), 6)
  end

  def page_logo_height
    resolve_pt(@styles.dig(:page_logo, :height), 20)
  end

  def page_logo_offset
    resolve_pt(@styles.dig(:page_logo, :offset), 0)
  end

  def page_logo_align
    @styles.dig(:page_logo, :align) || :right
  end

  def page_margin_top
    resolve_pt(@styles.dig(:page, :margin_top), 60)
  end

  def page_margin_left
    resolve_pt(@styles.dig(:page, :margin_left), 50)
  end

  def page_margin_right
    resolve_pt(@styles.dig(:page, :margin_right), 50)
  end

  def page_margin_bottom
    resolve_pt(@styles.dig(:page, :margin_bottom), 60)
  end

  def page_heading
    resolve_font(@styles[:page_heading])
  end

  def page_heading_margins
    resolve_margin(@styles[:page_heading])
  end

  def page_header
    resolve_font(@styles[:page_header])
  end

  def page_header_width
    @styles.dig(:page_header, :width).presence || 400
  end

  def page_footer
    resolve_font(@styles[:page_footer])
  end

  def page_break_threshold
    @page_break_threshold ||= resolve_pt(@styles.dig(:page, :page_break_threshold), 200)
  end

  def link_color
    @styles.dig(:page, :link_color) || "000000"
  end
end
