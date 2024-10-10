module WorkPackages::SplitViewHelper
  def render_work_package_split_view?
    params[:work_package_split_view].present? || params[:work_package_split_create].present?
  end

  def split_view_instance(project: nil)
    if params[:work_package_split_view]
      WorkPackages::SplitViewComponent.new(id: params[:work_package_id],
                                           tab: params[:tab],
                                           base_route: split_view_base_route)
    elsif params[:work_package_split_create].present?
      WorkPackages::SplitCreateComponent.new(type: params[:type],
                                             project:,
                                             base_route: split_view_base_route)
    end
  end

  def container_class
    "op-work-package-split-view"
  end
end
