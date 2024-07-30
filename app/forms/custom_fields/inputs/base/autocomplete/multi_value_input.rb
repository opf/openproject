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

class CustomFields::Inputs::Base::Autocomplete::MultiValueInput < CustomFields::Inputs::Base::Input
  def input_attributes
    base_input_attributes.merge(
      autocomplete_options:,
      wrapper_data_attributes: {
        "qa-field-name": qa_field_name
      }
    )
  end

  def autocomplete_options
    {
      multiple: true,
      decorated: decorated?,
      append_to:
    }
  end

  def decorated?
    raise NotImplementedError
  end

  def custom_values
    @custom_values ||= @object.custom_values_for_custom_field(id: @custom_field.id)
  end

  def invalid?
    custom_values.any? { |custom_value| custom_value.errors.any? }
  end

  def validation_message
    custom_values.map { |custom_value| custom_value.errors.full_messages }.join(", ") if invalid?
  end
end
