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

module CustomActions::Actions::Strategies::MeAssociated
  include ::CustomActions::Actions::Strategies::Associated

  def associated
    me_value = [current_user_value_key, I18n.t("custom_actions.actions.assigned_to.executing_user_value")]

    [me_value] + available_principles
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

  ##
  # Returns the me value if the user is logged
  def transformed_value(val)
    return val unless has_me_value?

    if User.current.logged?
      User.current.id
    end
  end

  def current_user_value_key
    "current_user".freeze
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
                 :not_logged_in,
                 name: human_name
    end
  end
end
