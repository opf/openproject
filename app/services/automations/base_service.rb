# frozen_string_literal: true

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
    set_triggers(action, triggers_attributes) if triggers_attributes
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
    action.assign_attributes(triggers_attributes: attributes)
  end
end
