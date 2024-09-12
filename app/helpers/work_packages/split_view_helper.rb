module WorkPackages::SplitViewHelper
  def render_work_package_split_view?
    params[:work_package_split_view].present?
  end

  def split_view_instance
    WorkPackages::SplitViewComponent.new(id: params[:work_package_id],
                                         tab: params[:tab],
                                         base_route: split_view_base_route)
  end
end
