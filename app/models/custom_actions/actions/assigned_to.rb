#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CustomActions::Actions::AssignedTo < CustomActions::Actions::Base
  include CustomActions::Actions::Strategies::Associated

  def self.key
    :assigned_to
  end

  def associated
    [[current_user_value_key, I18n.t('custom_actions.actions.assigned_to.executing_user_value')]] + available_principles
  end

  def values=(values)
    values = Array(values).map do |v|
      if v == current_user_value_key
        v
      else
        to_integer_or_nil(v)
      end
    end

    @values = values.uniq
  end

  def available_principles
    principal_class
      .active_or_registered
      .select(:id, :firstname, :lastname, :type)
      .order_by_name
      .map { |u| [u.id, u.name] }
  end

  def apply(work_package)
    work_package.assigned_to_id = transformed_value(values.first)
  end

  ##
  # Returns the me value if the user is logged
  def transformed_value(val)
    return val unless has_me_value?

    if User.current.logged?
      User.current.id
    end
  end

  def current_user_value_key
    'current_user'.freeze
  end

  def has_me_value?
    values.first == current_user_value_key
  end

  def validate(errors)
    super
    validate_me_value(errors)
  end

  private

  def validate_me_value(errors)
    if has_me_value? && !User.current.logged?
      errors.add :actions,
                 I18n.t(:'activerecord.errors.models.custom_actions.not_logged_in', name: human_name),
                 error_symbol: :not_logged_in
    end
  end

  def principal_class
    if Setting.work_package_group_assignment?
      Principal
    else
      User
    end
  end
end
