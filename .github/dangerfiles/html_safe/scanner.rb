# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
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

module HtmlSafeDangerScanner
  HTML_SAFE_CALL_REGEX = /\.html_safe(?![?_])/
  EMPTY_RECEIVER = /(['"])\1\z/
  SKIP_PATH_REGEX = %r{(?:\A|/)(?:spec|lookbook|docs|\.github/dangerfiles)/}

  module_function

  def skip_path?(file)
    file.match?(SKIP_PATH_REGEX)
  end

  def added_non_empty_html_safe_line?(line)
    return false unless line.start_with?("+")
    return false if line.start_with?("+++")

    contains_non_empty_html_safe?(line.delete_prefix("+"))
  end

  def contains_non_empty_html_safe?(code)
    code.to_enum(:scan, HTML_SAFE_CALL_REGEX).any? do
      !empty_html_safe_receiver?(code, Regexp.last_match.begin(0))
    end
  end

  def empty_html_safe_receiver?(code, dot_index)
    return false if dot_index < 2

    code[dot_index - 2, 2].match?(EMPTY_RECEIVER)
  end
end
