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

class CustomFields::Inputs::DateTime < CustomFields::Inputs::Base::Input
  form do |custom_value_form|
    custom_value_form.text_field(**input_attributes)
  end

  def input_attributes
    super.merge({ input_width: :small, type: "datetime-local" })
  end

  # The value is stored as a UTC ISO 8601 string, but a datetime-local input
  # requires a zone-less value in the user's local time.
  def value
    typed = custom_value&.typed_value
    return super unless typed.is_a?(::DateTime)

    typed.in_time_zone(User.current.time_zone).strftime("%Y-%m-%dT%H:%M")
  end
end
