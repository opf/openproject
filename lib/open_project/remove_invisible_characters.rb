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
  # Strips invisible characters from a string: ASCII control characters
  # and Unicode zero-width characters. Designed for use with
  # ActiveRecord's `normalizes` API:
  #
  #   normalizes :name, with: OpenProject::RemoveInvisibleCharacters
  #
  ASCII_CONTROL_CHARACTERS = /[\x00-\x1F\x7F]/
  ZERO_WIDTH_CHARACTERS = /[\u200B\u200C\u200D\uFEFF\u2060]/
  INVISIBLE_CHARACTERS = Regexp.union(ASCII_CONTROL_CHARACTERS, ZERO_WIDTH_CHARACTERS)

  private_constant :ASCII_CONTROL_CHARACTERS, :ZERO_WIDTH_CHARACTERS, :INVISIBLE_CHARACTERS

  RemoveInvisibleCharacters = ->(value) { value.is_a?(String) ? value.gsub(INVISIBLE_CHARACTERS, "") : value }
end
