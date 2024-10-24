module WorkPackages::SplitViewHelper
  def render_work_package_split_view?
    params[:view_type].present?
  end

  def split_view_instance(view_type:, project: nil)
    case view_type
    when "work_package_split_view"
      WorkPackages::SplitView::ShowComponent.new(id: params[:work_package_id],
                                                 tab: params[:tab],
                                                 base_route: split_view_base_route)
    when "work_package_split_create"
      WorkPackages::SplitView::CreateComponent.new(type: params[:type],
                                                   project:,
                                                   base_route: split_view_base_route)
    else
      # TODO
    end
  end

  def container_class
    "op-work-package-split-view"
  end
end
