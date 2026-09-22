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

module OpenProject
  module TextFormatting
    module Truncation
      # Used for truncation
      include ActionView::Helpers::TextHelper

      ##
      # Truncates and returns the string as a single line
      #
      # @overload truncate_single_line(text, options = {}, &block)
      #   @param [String] text the string to truncate.
      #   @param [Hash] options
      #   @option options [Number] :length (30)
      #     The maximum number of characters that should be returned, excluding
      #     any extra content from the block.
      #   @option options [String] :omission ("...")
      #     The string to append after truncating.
      #   @option options [String, RegExp] :separator
      #     A string or regexp used to find a breaking point at which to
      #     truncate. By default, truncation can occur at any character in text.
      #   @option options [Boolean] :escape (true)
      #     Whether to escape the result.
      #
      # @see ActionView::Helpers::TextHelper#truncate
      # @return [String] an HTML-safe safe string as single-line.
      def truncate_single_line(text, *)
        truncated = truncate(text, *)
        return truncated unless truncated

        truncated.html_safe_gsub(/[\r\n]+/, " ")
      end
    end
  end
end
