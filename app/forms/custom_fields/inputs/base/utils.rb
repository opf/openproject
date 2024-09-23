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

module CustomFields::Inputs::Base::Utils
  def base_input_attributes
    {
      name:,
      label:,
      value:,
      required: required?,
      invalid: invalid?,
      validation_message:
    }
  end

  def name
    @custom_field.id.to_s
  end

  def label
    @custom_field.name
  end

  def value
    @custom_value
  end

  def required?
    @custom_field.is_required?
  end

  def qa_field_name
    @custom_field.attribute_name(:kebab_case)
  end

  # used within autocompleter inputs
  def append_to
    options.fetch(:wrapper_id, "body")
  end
end
