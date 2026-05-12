# frozen_string_literal: true

require "model_contract"

module Automations
  class CuContract < ::ModelContract
    def self.model
      Automation
    end

    attribute :name
    attribute :description

    attribute :actions do
      live_actions = model.actions.reject(&:marked_for_destruction?)
      errors.add(:actions, :empty) if live_actions.empty?
      live_actions.each { |action| action.validate(errors) }
    end

    attribute :conditions do
      model.conditions.each { |condition| condition.validate(errors) }
    end
  end
end
