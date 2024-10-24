# frozen_string_literal: true

module OpenProject::WorkPackages
  # @logical_path OpenProject/WorkPackages
  class StatusBadgeComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param size [Symbol] select [ medium, large]
    # @param inline [Boolean]
    def playground(size: :medium, inline: false)
      # Colors will be applied in code as well but there are not loaded in the lookbook
      render(WorkPackages::StatusBadgeComponent.new(status: Status.first, size:, inline:))
    end
  end
end
