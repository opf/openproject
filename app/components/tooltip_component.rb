# frozen_string_literal: true

class TooltipComponent < ViewComponent::Base
  renders_one :trigger
  renders_one :body

  def initialize(alignment: 'bottom-center')
    @alignment = alignment
  end
end
