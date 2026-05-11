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
      errors.add(:actions, :empty) if model.actions.empty?
      model.actions.each { |action| action.validate(errors) }
    end

    attribute :conditions do
      model.conditions.each { |condition| condition.validate(errors) }
    end
  end
end
