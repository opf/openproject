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

class CustomActions::BaseService
  include Shared::BlockService

  attr_accessor :user

  def call(attributes:,
           action:,
           &)
    set_attributes(action, attributes)

    contract = CustomActions::CuContract.new(action)
    result = ServiceResult.new(success: contract.validate && action.save,
                               result: action,
                               errors: contract.errors)

    block_with_result(result, &)
  end

  private

  def set_attributes(action, attributes)
    actions_attributes = attributes.delete(:actions)
    conditions_attributes = attributes.delete(:conditions)
    action.attributes = attributes

    set_actions(action, actions_attributes.symbolize_keys) if actions_attributes
    set_conditions(action, conditions_attributes.symbolize_keys) if conditions_attributes
  end

  def set_actions(action, actions_attributes)
    existing_action_keys = action.actions.map(&:key)

    remove_actions(action, existing_action_keys - actions_attributes.keys)
    update_actions(action, actions_attributes.slice(*existing_action_keys))
    add_actions(action, actions_attributes.slice(*(actions_attributes.keys - existing_action_keys)))
  end

  def remove_actions(action, keys)
    keys.each do |key|
      remove_action(action, key)
    end
  end

  def update_actions(action, key_values)
    key_values.each do |key, values|
      update_action(action, key, values)
    end
  end

  def add_actions(action, key_values)
    key_values.each do |key, values|
      add_action(action, key, values)
    end
  end

  def update_action(action, key, values)
    action.actions.detect { |a| a.key == key }.values = values
  end

  def add_action(action, key, values)
    action.actions << available_action_for(action, key).new(values)
  end

  def remove_action(action, key)
    action.actions.reject! { |a| a.key == key }
  end

  def set_conditions(action, conditions_attributes)
    action.conditions = conditions_attributes.map do |key, values|
      available_condition_for(action, key).new(values)
    end
  end

  def available_action_for(action, key)
    action.available_actions.detect { |a| a.key == key } || CustomActions::Actions::Inexistent
  end

  def available_condition_for(action, key)
    action.available_conditions.detect { |a| a.key == key } || CustomActions::Conditions::Inexistent
  end
end
