# frozen_string_literal: true

class WorkPackages::SplitViewComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  def initialize(id:, base_route:, tab: "overview")
    super

    @id = id
    @tab = tab
    @work_package = WorkPackage.visible.find_by(id:)
    @base_route = base_route
  end
end
