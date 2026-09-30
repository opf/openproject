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

module Exports::PDF::Components::CoverStyles
  def cover_header
    resolve_font(@styles.dig(:cover, :header))
  end

  def cover_header_logo_height
    resolve_pt(@styles.dig(:cover, :header, :logo_height), 25)
  end

  def cover_header_border
    { color: @styles.dig(:cover, :header, :border, :color),
      height: resolve_pt(@styles.dig(:cover, :header, :border, :height), 1),
      offset: resolve_pt(@styles.dig(:cover, :header, :border, :offset), 0) }
  end

  def cover_footer
    resolve_font(@styles.dig(:cover, :footer))
  end

  def cover_footer_offset
    resolve_pt(@styles.dig(:cover, :footer, :offset), 0)
  end

  def cover_hero_padding
    resolve_padding(@styles.dig(:cover, :hero))
  end

  def cover_hero_title
    resolve_font(@styles.dig(:cover, :hero, :title))
  end

  def cover_hero_title_spacing
    resolve_pt(@styles.dig(:cover, :hero, :title, :spacing), 0)
  end

  def cover_hero_title_max_height
    resolve_pt(@styles.dig(:cover, :hero, :title, :max_height), 30)
  end

  def cover_hero_heading
    resolve_font(@styles.dig(:cover, :hero, :heading))
  end

  def cover_hero_heading_spacing
    resolve_pt(@styles.dig(:cover, :hero, :heading, :spacing), 0)
  end

  def cover_hero_dates
    resolve_font(@styles.dig(:cover, :hero, :dates))
  end

  def cover_hero_dates_spacing
    resolve_pt(@styles.dig(:cover, :hero, :dates, :spacing), 0)
  end

  def cover_hero_dates_max_height
    resolve_pt(@styles.dig(:cover, :hero, :dates, :max_height), 0)
  end

  def cover_hero_subheading
    resolve_font(@styles.dig(:cover, :hero, :subheading))
  end

  def cover_hero_subheading_max_height
    resolve_pt(@styles.dig(:cover, :hero, :subheading, :max_height), 30)
  end
end
