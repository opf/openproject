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

module OpenProject::TextFormatting
  module Renderer
    module_function

    # @note
    #   Consider the {OpenProject::TextFormatting#format_text} convenience
    #   method instead, particularly if you are formatting model attributes.
    #
    # @param [String] text the raw text to be formatted, typically Markdown.
    # @param (see .formatter_for)
    # @param [Hash] context context arguments to pass to underlying rendering
    #   pipeline (see {Formats::BaseFormatter#initialize}).
    # @return [String] the formatted text as an HTML-safe String.
    def format_text(text, format: :rich, **context)
      return "".html_safe if text.blank?

      formatter_for(format)
        .new(context)
        .to_html(text)
    end

    # @param [:plain, :rich] format the text format.
    # @return [Formats::BaseFormatter] a formatter implementation.
    def formatter_for(format)
      case format.to_sym
      when :plain
        Formats.plain_formatter
      else
        Formats.rich_formatter
      end
    end
  end
end
