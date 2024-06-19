# frozen_string_literal: true

class WorkPackages::Details::TabComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  def initialize(id:, tab: :overview)
    @id = id
    @tab = tab.to_sym
  end
end
