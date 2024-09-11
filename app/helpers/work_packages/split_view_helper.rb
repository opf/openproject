module WorkPackages::SplitViewHelper
  def optional_work_package_split_view
    return unless params[:work_package_split_view]

    content_for :content_body_right do
      render split_view_instance
    end
  end

  def split_view_instance
    WorkPackages::SplitViewComponent.new(id: params[:work_package_id],
                                         tab: params[:tab],
                                         base_route: split_view_base_route)
  end
end
