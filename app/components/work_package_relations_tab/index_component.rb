# frozen_string_literal: true

class WorkPackageRelationsTab::IndexComponent < ApplicationComponent
  FRAME_ID = "work-package-relations-tab-content"
  include ApplicationHelper
  include OpPrimer::ComponentHelpers
  include Turbo::FramesHelper
  include OpTurbo::Streamable

  attr_reader :work_package, :relations

  def initialize(work_package:, relations:)
    super()

    @work_package = work_package
    @relations = relations
  end

  def self.wrapper_key
    FRAME_ID
  end
end
