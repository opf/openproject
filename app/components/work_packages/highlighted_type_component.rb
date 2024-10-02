# frozen_string_literal: true

class WorkPackages::HighlightedTypeComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, **system_arguments)
    super

    @type = work_package.type
    @system_arguments = system_arguments
  end

  def call
    render(Primer::Beta::Text.new(classes: "__hl_inline_type_#{@type.id}"), **@system_arguments) { @type.name.upcase }
  end
end
