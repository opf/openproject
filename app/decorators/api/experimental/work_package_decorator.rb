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

class API::Experimental::WorkPackageDecorator < SimpleDelegator
  def self.decorate(collection)
    collection.map do |wp|
      new(wp)
    end
  end

  def custom_values_display_data(field_ids)
    field_ids = Array(field_ids)
    field_ids.map do |field_id|
      value = custom_values.detect do |cv|
        cv.custom_field_id == field_id.to_i
      end

      get_cast_custom_value_with_meta(value)
    end
  end

  private

  def get_cast_custom_value_with_meta(custom_value)
    return unless custom_value

    custom_field = custom_value.custom_field
    value = if custom_field.field_format == 'user'
              custom_value.typed_value.as_json(methods: :name)
            else
              custom_value.typed_value
            end

    {
      custom_field_id: custom_field.id,
      field_format: custom_field.field_format, # TODO just return the cast value
      value: value
    }
  end
end
