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

# Provides translated error messages for CalculatedValueError instances.
module CalculatedValues::ErrorsHelper
  DEFAULT_TRANSLATION = "calculated_values.errors.unknown"

  ERROR_TRANSLATIONS = {
    "ERROR_UNKNOWN" => DEFAULT_TRANSLATION,
    "ERROR_MATHEMATICAL" => "calculated_values.errors.mathematical",
    "ERROR_MISSING_VALUE" => "calculated_values.errors.missing_value",
    "ERROR_DISABLED_VALUE" => "calculated_values.errors.disabled_value"
  }.freeze

  def calculated_value_error_msg(calculated_value_error)
    return unless calculated_value_error.is_a?(CalculatedValueError)

    error_code = calculated_value_error.error_code
    missing_custom_field_ids = calculated_value_error.missing_custom_field_ids

    translation_key = ERROR_TRANSLATIONS.fetch(error_code, DEFAULT_TRANSLATION)
    translation_options = {}

    if %w[ERROR_MISSING_VALUE ERROR_DISABLED_VALUE].include?(error_code)
      # To keep the error message short, we only show the first custom field with a missing/disabled value.
      # TODO: This is also N+1 problematic.
      cf = CustomField.find_by(id: missing_custom_field_ids.first)

      if cf
        translation_options[:custom_field_name] = cf.name
      else
        translation_key = DEFAULT_TRANSLATION
      end
    end

    I18n.t(translation_key, **translation_options)
  end

  module_function :calculated_value_error_msg
end
