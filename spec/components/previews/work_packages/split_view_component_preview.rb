# frozen_string_literal: true

class WorkPackages::SplitViewComponentPreview < ViewComponent::Preview
  def default
    render(WorkPackages::SplitViewComponent.new(id: "1", tab: "tab", base_url: work_packages_path))
  end
end
