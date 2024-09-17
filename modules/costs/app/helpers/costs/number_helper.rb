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

module Costs::NumberHelper
  # Turns a string representing a number in the current locale
  # to a string representing a number in en (without delimiters).
  def parse_number_string(value)
    return value unless value&.is_a?(String) && value.present?

    value = value.strip

    # All locales seem to have their delimiters set to "".
    # We thus remove all typical delimiters that are not the separator.
    separator =
      if I18n.exists?(:"number.currency.format.separator")
        I18n.t(:"number.currency.format.separator")
      else
        I18n.t(:"number.format.separator", default: ".")
      end

    if separator
      delimiters = Regexp.new("[ .,’˙]".gsub(separator, ""))

      value.gsub!(delimiters, "")

      value.gsub!(separator, ".")
    end

    value
  end

  # Turns a string representing a number in the current locale
  # to a BigDecimal number.
  #
  # In case the string cannot be parsed, 0.0 is returned.
  def parse_number_string_to_number(value)
    BigDecimal(parse_number_string(value))
  rescue TypeError, ArgumentError
    0.0
  end

  # Output currency value without unit
  def unitless_currency_number(value)
    number_to_currency(value, format: "%n")
  end

  def to_currency_with_empty(rate)
    rate.nil? ? "0.0" : number_to_currency(rate.rate)
  end
end
