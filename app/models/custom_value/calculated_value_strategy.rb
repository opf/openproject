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

class CustomValue::CalculatedValueStrategy < CustomValue::FormatStrategy
  include ActionView::Helpers::NumberHelper

  def typed_value
    if value.blank?
      nil
    elsif true_value?
      true
    elsif false_value?
      false
    elsif integer_value?
      value.to_i
    else
      value.to_f
    end
  end

  def formatted_value
    if value.blank?
      ""
    elsif true_value?
      I18n.t(:general_text_Yes)
    elsif false_value?
      I18n.t(:general_text_No)
    elsif integer_value?
      number_with_delimiter(value.to_i)
    else
      formatted_as_float
    end
  end

  def parse_value(val)
    case val
    when true, "true", OpenProject::Database::DB_VALUE_TRUE
      OpenProject::Database::DB_VALUE_TRUE
    when false, "false", OpenProject::Database::DB_VALUE_FALSE
      OpenProject::Database::DB_VALUE_FALSE
    else
      val
    end
  end

  def validate_type_of_value
    return if value.in?([true, false]) || true_value? || false_value?

    :not_a_number unless Kernel.Float(value, exception: false)
  end

  private

  def true_value?
    value == OpenProject::Database::DB_VALUE_TRUE
  end

  def false_value?
    value == OpenProject::Database::DB_VALUE_FALSE
  end

  def integer_value?
    value =~ /\A[-+]?\d+\z/
  end

  def formatted_as_float
    delimiter = I18n.t("number.format.delimiter")
    separator = I18n.t("number.format.separator")
    formatted = number_with_precision(
      value.to_f,
      precision: 3,
      strip_insignificant_zeros: true,
      delimiter:,
      separator:
    )

    # Ensure at least one decimal place for floats
    if formatted.exclude?(separator)
      "#{formatted}#{separator}0"
    else
      formatted
    end
  end
end
