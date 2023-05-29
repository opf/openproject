# frozen_string_literal: true

class SwitchComponentPreview < ViewComponent::Preview

  # This component describes only the actual switch, without the label.
  # For the full component, please refer to Selector field component, which provides a label.
  # @param checked toggle
  # @param disabled toggle
  def default(checked: false, disabled: false)
    render(SwitchComponent.new(checked:, disabled:))
  end

  # @param checked toggle
  def disabled(checked: true)
    render(SwitchComponent.new(checked:, disabled: true))
  end
end
