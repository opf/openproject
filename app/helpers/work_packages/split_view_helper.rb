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
                                         base_route: params[:base_route] || work_packages_path)
  end

  def respond_to_with_split_view(&format_block)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("content-bodyRight", split_view_instance.render_in(view_context))
      end

      yield(format) if format_block
    end
  end
end
