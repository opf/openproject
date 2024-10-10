# frozen_string_literal: true

class WorkPackages::SplitCreateComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  def initialize(type:, project:, base_route:)
    super

    @type = type
    @project = project
    @base_route = base_route
  end
end
