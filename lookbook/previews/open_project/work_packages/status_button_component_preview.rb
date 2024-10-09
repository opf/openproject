# frozen_string_literal: true

module OpenProject::WorkPackages
  # @logical_path OpenProject/WorkPackages
  class StatusButtonComponentPreview < ViewComponent::Preview
    # !! Currently nothing happens when changing the status!!
    # @display min_height 400px
    # @param readonly [Boolean]
    # @param size [Symbol] select [small, medium, large]
    def playground(readonly: true, size: :medium)
      user = FactoryBot.build_stubbed(:admin)
      render(WorkPackages::StatusButtonComponent.new(work_package: WorkPackage.visible.first,
                                                     user:,
                                                     readonly:,
                                                     button_arguments: { size: }))
    end
  end
end
