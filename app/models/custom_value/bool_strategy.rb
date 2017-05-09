#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class CustomValue::BoolStrategy < CustomValue::FormatStrategy
  DB_VALUE_FALSE = 'f'.freeze
  DB_VALUE_TRUE = 't'.freeze

  def value_present?
    present?(value)
  end

  def typed_value
    return nil unless value_present?

    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def formatted_value
    is_true = ActiveRecord::Type::Boolean.new.cast(value)
    I18n.t(is_true ? :general_text_Yes : :general_text_No)
  end

  def parse_value(val)
    parsed_val = if !present?(val)
                   nil
                 elsif ActiveRecord::Type::Boolean::FALSE_VALUES.include?(val)
                   DB_VALUE_FALSE
                 else
                   DB_VALUE_TRUE
                 end

    super(parsed_val)
  end

  def validate_type_of_value; end

  private

  def present?(val)
    # can't use :blank? safely, because false.blank? == true
    # can't use :present? safely, because false.present? == false
    !val.nil? && val != ''
  end
end
