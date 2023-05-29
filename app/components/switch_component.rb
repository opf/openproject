# frozen_string_literal: true

class SwitchComponent < ViewComponent::Base
  def initialize(checked: false, disabled: false, name: nil)
    @checked = checked
    @disabled = disabled
    @name = name
  end
end
