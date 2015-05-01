#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class OpenProject::JournalFormatter::CustomField < ::JournalFormatter::Base
  # unloadable

  include CustomFieldsHelper

  private

  def format_details(key, values)
    custom_field = CustomField.find_by_id(key.to_s.sub('custom_fields_', '').to_i)

    if custom_field
      label = custom_field.name
      old_value = format_value(values.first, custom_field.field_format) if values.first
      value = format_value(values.last, custom_field.field_format) if values.last
    else
      label = l(:label_deleted_custom_field)
      old_value = values.first
      value = values.last
    end

    [label, old_value, value]
  end
end
