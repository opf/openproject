class WorkPackageRelationsTab::RelationComponent < ApplicationComponent
  include ApplicationHelper
  include OpPrimer::ComponentHelpers

  attr_reader :work_package

  def initialize(work_package:)
    super()

    @work_package = work_package
  end
end
