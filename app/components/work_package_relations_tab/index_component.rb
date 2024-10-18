class WorkPackageRelationsTab::IndexComponent < ApplicationComponent
  include ApplicationHelper
  include OpPrimer::ComponentHelpers
  include Turbo::FramesHelper

  def initialize(work_package:, relations:)
    super()

    @work_package = work_package
    @relations = relations
  end
end
