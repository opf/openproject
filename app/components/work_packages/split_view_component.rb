# frozen_string_literal: true

class WorkPackages::SplitViewComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  def initialize(id:, tab: 'overview')
    @id = id
    @tab = tab
    @work_package = WorkPackage.visible.find_by(id:)
  end
end
