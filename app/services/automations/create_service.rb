# frozen_string_literal: true

class Automations::CreateService < Automations::BaseService
  def initialize(user:)
    self.user = user
  end

  def call(attributes:, action: Automation.new, &block)
    super
  end
end
