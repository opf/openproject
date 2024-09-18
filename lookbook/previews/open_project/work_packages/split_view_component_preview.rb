# frozen_string_literal: true

module OpenProject::WorkPackages
  # @logical_path OpenProject/WorkPackages
  class SplitViewComponentPreview < ViewComponent::Preview
    # @display min_height 400px
    def default
      render(WorkPackages::SplitViewComponent.new(id: WorkPackage.visible.pick(:id), tab: "overview",
                                                  base_route: work_packages_path))
    end
  end
end
