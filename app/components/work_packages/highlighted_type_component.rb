# frozen_string_literal: true

class WorkPackages::HighlightedTypeComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, **system_arguments)
    super

    @type = work_package.type
    @system_arguments = system_arguments.merge({ classes: "__hl_inline_type_#{@type.id}" })
  end

  def call
    render(Primer::Beta::Text.new(**@system_arguments)) { @type.name.upcase }
  end
end
