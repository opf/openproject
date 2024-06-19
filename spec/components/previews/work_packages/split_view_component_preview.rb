# frozen_string_literal: true

class WorkPackages::SplitViewComponentPreview < ViewComponent::Preview
  def default
    render(WorkPackages::SplitViewComponent.new(work_package: "work_package", tab: "tab"))
  end
end
