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

class CustomValue::BoolStrategy < CustomValue::FormatStrategy
  def value_present?
    present?(value)
  end

  def typed_value
    return nil unless value_present?

    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def formatted_value
    if checked?
      I18n.t(:general_text_Yes)
    else
      I18n.t(:general_text_No)
    end
  end

  def checked?
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def parse_value(val)
    parsed_val = if !present?(val)
                   nil
                 elsif ActiveRecord::Type::Boolean::FALSE_VALUES.include?(val)
                   OpenProject::Database::DB_VALUE_FALSE
                 else
                   OpenProject::Database::DB_VALUE_TRUE
                 end

    super(parsed_val)
  end

  def validate_type_of_value; end

  private

  def present?(val)
    # can't use :blank? safely, because false.blank? == true
    # can't use :present? safely, because false.present? == false
    !val.nil? && val != ""
  end
end
