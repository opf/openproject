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

class Automations::BaseService
  include Shared::BlockService

  attr_accessor :user

  def call(attributes:,
           automation:,
           &)
    set_attributes(automation, attributes)

    contract = Automations::CuContract.new(automation, user)
    result = ServiceResult.new(success: contract.validate && automation.save,
                               result: automation,
                               errors: contract.errors)

    block_with_result(result, &)
  end

  private

  def set_attributes(automation, attributes)
    actions_attributes = attributes.delete(:actions)
    conditions_attributes = attributes.delete(:conditions)
    triggers_attributes = attributes.delete(:triggers_attributes)

    automation.attributes = attributes
    set_actions(automation, actions_attributes.symbolize_keys) if actions_attributes
    set_conditions(automation, conditions_attributes.symbolize_keys) if conditions_attributes
    set_triggers(automation, triggers_attributes)
  end

  def set_actions(automation, actions_attributes)
    existing_action_keys = automation.actions.map(&:key)

    remove_actions(automation, existing_action_keys - actions_attributes.keys)
    update_actions(automation, actions_attributes.slice(*existing_action_keys))
    add_actions(automation, actions_attributes.slice(*(actions_attributes.keys - existing_action_keys)))
  end

  def remove_actions(automation, keys)
    keys.each { |key| remove_action(automation, key) }
  end

  def update_actions(automation, key_values)
    key_values.each { |key, values| update_action(automation, key, values) }
  end

  def add_actions(automation, key_values)
    key_values.each { |key, values| add_action(automation, key, values) }
  end

  def update_action(automation, key, values)
    automation.actions.detect { |a| a.key == key }.values = values
  end

  def add_action(automation, key, values)
    automation.actions << available_action_for(automation, key).new(values)
  end

  def remove_action(automation, key)
    automation.actions.reject! { |a| a.key == key }
  end

  def set_conditions(automation, conditions_attributes)
    automation.conditions = conditions_attributes.map do |key, values|
      available_condition_for(automation, key).new(values)
    end
  end

  def available_action_for(automation, key)
    automation.available_actions.detect { |a| a.key == key } || Automations::Actions::Inexistent
  end

  def available_condition_for(automation, key)
    automation.available_conditions.detect { |a| a.key == key } || Automations::Conditions::Inexistent
  end

  def set_triggers(automation, attributes)
    return if attributes.blank?

    automation.assign_attributes(triggers_attributes: attributes)
  end
end
