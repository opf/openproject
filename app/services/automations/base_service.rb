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
           action:,
           &)
    set_attributes(action, attributes)

    contract = Automations::CuContract.new(action, user)
    result = ServiceResult.new(success: contract.validate && action.save,
                               result: action,
                               errors: contract.errors)

    block_with_result(result, &)
  end

  private

  def set_attributes(action, attributes)
    actions_attributes = attributes.delete(:actions)
    conditions_attributes = attributes.delete(:conditions)
    triggers_attributes = attributes.delete(:triggers_attributes)

    action.attributes = attributes
    set_actions(action, actions_attributes.symbolize_keys) if actions_attributes
    set_conditions(action, conditions_attributes.symbolize_keys) if conditions_attributes
    set_triggers(action, triggers_attributes)
  end

  def set_actions(automation, actions_attributes)
    existing_by_key = automation.actions.index_by(&:key)
    incoming_keys = actions_attributes.keys.map(&:to_sym)

    (existing_by_key.keys - incoming_keys).each do |key|
      existing_by_key[key].mark_for_destruction
    end

    actions_attributes.each do |key, values|
      key = key.to_sym
      if (existing = existing_by_key[key])
        existing.values = values
      else
        add_action(automation, key, values)
      end
    end
  end

  def add_action(automation, key, values)
    template = automation.available_actions.detect { |a| a.key == key } ||
               Automations::Actions::Inexistent.new

    new_action = template.dup
    new_action.values = values
    automation.actions << new_action
  end

  def set_conditions(action, conditions_attributes)
    action.conditions = conditions_attributes.map do |key, values|
      available_condition_for(action, key).new(values)
    end
  end

  def available_condition_for(action, key)
    action.available_conditions.detect { |a| a.key == key } || Automations::Conditions::Inexistent
  end

  def set_triggers(action, attributes)
    attributes ||= default_trigger_attributes(action)
    return if attributes.blank?

    action.assign_attributes(triggers_attributes: attributes)
  end

  def default_trigger_attributes(action)
    return [] if action.triggers.any?(Automations::Triggers::Manual)

    [{ type: "Automations::Triggers::Manual", options: { button_label: action.name } }]
  end
end
