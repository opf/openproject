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

# The module is not called I18n as that leads to tons of conflicts
# where I18n is called within the OpenProject module and rails I18n is meant.

module OpenProject
  module Internationalization
    module JsDateTimeFormat
      module_function

      DATE_SPECIFIERS = {
        "%Y" => "YYYY",
        "%y" => "YY",
        "%m" => "MM",
        "%B" => "MMMM",
        "%b" => "MMM",
        "%h" => "MMM",
        "%d" => "DD",
        "%e" => "D",
        "%j" => "DDDD"
      }.freeze

      TIME_SPECIFIERS = {
        "%H" => "HH",
        "%k" => "H",
        "%I" => "hh",
        "%l" => "h",
        "%P" => "a",
        "%p" => "A",
        "%M" => "mm"
      }.freeze

      def date(strftime_format) = strftime_format&.gsub(/%\w/, DATE_SPECIFIERS).presence

      def time(strftime_format) = strftime_format&.gsub(/%\w/, TIME_SPECIFIERS).presence
    end
  end
end
