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

module OpPrimer
  # Clamps block content to a fixed number of lines via CSS `-webkit-line-clamp`,
  # styled through the `.op-vertical-truncate` class hierarchy.
  #
  # The vertical counterpart to `Primer::Beta::Truncate` (which clips a single
  # line horizontally). Like `Truncate`, it wraps whatever block content it is
  # given; callers pass system arguments (e.g. `flex:`, `data:`) through.
  class VerticalTruncateComponent < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
    LINES_MINIMUM = 2
    LINES_DEFAULT = 3

    # @param lines [Integer] number of visible rows (at least 2; a single line is
    #   `Primer::Beta::Truncate`'s job). Applied via the
    #   `--op-vertical-truncate-lines` custom property rather than a per-count
    #   modifier class, so any count from 2 up is supported.
    # @param tag [Symbol] wrapping element; defaults to `:div` (safe for block
    #   content). Overridable, mirroring `Primer::Beta::Truncate`.
    # @param system_arguments [Hash] forwarded to the wrapping `Primer::BaseComponent`.
    def initialize(lines: LINES_DEFAULT, **system_arguments)
      super()

      @system_arguments = system_arguments
      @system_arguments[:tag] ||= :div

      lines = [lines.to_i, LINES_MINIMUM].max
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-vertical-truncate"
      )
      @system_arguments[:style] = join_style_arguments(
        @system_arguments[:style],
        "--op-vertical-truncate-lines: #{lines};"
      )
    end

    def call
      render(Primer::BaseComponent.new(**@system_arguments)) { content }
    end
  end
end
