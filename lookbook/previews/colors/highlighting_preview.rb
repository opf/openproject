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

module Colors
  # @logical_path OpenProject
  class HighlightingPreview < Lookbook::Preview
    # Fractions of the way through the palette ordered by perceived lightness. Spread so
    # that the point where __hl_background flips its text from white to black is visible.
    SAMPLE_POSITIONS = [0.0, 0.3, 0.45, 0.55, 0.75, 1.0].freeze

    # @display min_height 280px
    # @label Usage classes
    def usage_classes
      render_with_template(locals: { colors: sample_colors })
    end

    # @display min_height 140px
    # @label Dot sizes
    def dot_sizes
      render_with_template(locals: { colors: sample_colors.first(2) })
    end

    # @display min_height 200px
    # @label Resource without a color
    def without_color
      render_with_template
    end

    # @display min_height 140px
    # @label Overdue dates
    def overdue_dates
      render_with_template
    end

    private

    # Real Color records, so the previews exercise the generated `__hl_color_<id>` rules
    # rather than a hand written approximation of them.
    def sample_colors
      by_lightness = Color.all.sort_by(&:perceived_lightness)
      return [] if by_lightness.empty?

      positions = SAMPLE_POSITIONS.map { ((by_lightness.size - 1) * it).round }
      by_lightness.values_at(*positions.uniq)
    end
  end
end
