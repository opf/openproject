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

module Automations::Actions::Strategies::UserCustomField
  include ::Automations::Actions::Strategies::CustomField
  include ::Automations::Actions::Strategies::MeAssociated

  def type
    :user
  end

  def available_principles
    custom_field.possible_values_options.map { |label, value| [value.empty? ? nil : value.to_i, label] }
  end

  # Implement the apply method explicitly, because the MeAssociated module would override the default
  # implementation. This could have been solved by swapping the module includes, however then the
  # transformed_value method would get an incorrect implementation.
  def apply(work_package)
    if work_package.respond_to?(custom_field.attribute_setter)
      set_custom_field_value(work_package)
      validate_custom_field(work_package)
    end
  end

  private

  def set_custom_field_value(work_package)
    work_package.send(custom_field.attribute_setter, transformed_values(work_package))
  end

  def transformed_values(work_package)
    if single_value?
      transformed_value values.first
    else
      me_handled = values.map { transformed_value(it) }
      me_handled & available_principal_ids_for(work_package)
    end
  end

  def transformed_value(value)
    if value == current_user_value_key
      User.current.id if User.current.logged?
    else
      value
    end
  end

  def single_value? = !multi_value?

  def available_principal_ids_for(work_package)
    custom_field.possible_values_options(work_package).map { |_, value| value.empty? ? nil : value.to_i }
  end
end
