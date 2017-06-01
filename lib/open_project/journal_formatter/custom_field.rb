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

class OpenProject::JournalFormatter::CustomField < ::JournalFormatter::Base
  include CustomFieldsHelper

  private

  def format_details(key, values)
    custom_field = CustomField.find_by(id: key.to_s.sub('custom_fields_', '').to_i)

    if custom_field
      label = custom_field.name
      old_value, value = get_old_and_new_value custom_field, values
    else
      label = I18n.t(:label_deleted_custom_field)
      old_value = values.first
      value = values.last
    end

    [label, old_value, value]
  end

  def get_old_and_new_value(custom_field, values)
    if custom_field.list?
      format_list custom_field, values
    elsif custom_field.multi_value?
      format_multi custom_field, values
    else
      format_single custom_field, values
    end
  end

  def format_list(custom_field, values)
    old_value, new_value = values
    old_option = find_list_value custom_field, old_value if old_value
    new_option = find_list_value custom_field, new_value if new_value

    [old_option || old_value, new_option || new_value]
  end

  def format_multi(custom_field, values)
    old_value, new_value = values.map { |vs| formatted_values custom_field, vs }

    [old_value, new_value]
  end

  def format_single(custom_field, values)
    old_value = format_value(values.first, custom_field) if values.first
    value = format_value(values.last, custom_field) if values.last

    [old_value, value]
  end

  def find_list_value(custom_field, id)
    if custom_field.multi_value?
      custom_field_values(custom_field, id).join(", ")
    else
      custom_field.custom_options.find_by(id: id).try(:value)
    end
  end

  def formatted_values(custom_field, values)
    String(values)
      .split(",")
      .map(&:strip)
      .map { |value| format_value value, custom_field }
      .join(", ")
      .presence
  end

  def custom_field_values(custom_field, id)
    custom_field
      .custom_options
      .where(id: id.split(","))
      .pluck(:value)
      .select(&:present?)
  end
end
