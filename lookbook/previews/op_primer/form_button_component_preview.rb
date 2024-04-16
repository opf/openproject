# frozen_string_literal: true

class OpPrimer::FormButtonComponentPreview < ViewComponent::Preview
  def default
    render(OpPrimer::FormButtonComponent.new)
  end
end
