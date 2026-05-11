# frozen_string_literal: true

class Automations::UpdateService < Automations::BaseService
  attr_accessor :user,
                :action

  def initialize(action:, user:)
    self.action = action
    self.user = user
  end

  def call(attributes:, &)
    super(attributes:, action:, &)
  end
end
