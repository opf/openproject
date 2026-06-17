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
  # @logical_path OpenProject/Primer
  class ExpandableTextComponentPreview < ViewComponent::Preview
    # Interactive playground for all modes. Switch `truncate` to `multi_line` to
    # see line-clamping, and `expansion` to `dialog` to reveal the full text in a
    # dialog.
    # @param text "The text content to display" text
    # @param width "Container width in pixels" range { min: 100, max: 600, step: 10 }
    # @param truncate "Truncation style" select { choices: [single_line, multi_line] }
    # @param lines "Lines (multi_line mode only)" range { min: 2, max: 8, step: 1 }
    # @param expansion "Reveal text in place or in a dialog" select { choices: [inline, dialog] }
    def playground(text: "OpenProject is an open source project management software that supports " \
                         "classic, agile, and hybrid approaches.",
                   width: 200, truncate: :single_line, lines: 3, expansion: :inline)
      render_with_template(locals: { text:, width:, truncate: truncate.to_sym, lines:, expansion: expansion.to_sym })
    end

    # Single-line truncation with inline expansion (default)
    def default
      render_with_template
    end

    # Text that fits its container — the expander stays hidden until the content
    # overflows. (An empty-looking preview is expected here.)
    def hidden_for_short_texts
      render(OpPrimer::ExpandableTextComponent.new) { "Short text" }
    end

    # Single-line truncation inside a table, mimicking the Permissions Report layout
    # @display min_height 300px
    def in_table
      render_with_template
    end

    # Multi-line truncation with inline expansion using line-clamp
    # @param lines "Number of visible lines" range { min: 2, max: 8, step: 1 }
    # @display min_height 300px
    def multi_line(lines: 3)
      render_with_template(locals: { lines: })
    end

    # Multi-line truncation where the expander opens a dialog instead of expanding inline
    # @display min_height 300px
    def dialog
      render_with_template
    end
  end
end
