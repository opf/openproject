class WorkPackageRelationsTab::IndexComponent < ApplicationComponent
  include ApplicationHelper
  include OpPrimer::ComponentHelpers
  include Turbo::FramesHelper

  attr_reader :work_package, :relations

  def initialize(work_package:, relations:)
    super()

    @work_package = work_package
    @relations = relations
  end
end
