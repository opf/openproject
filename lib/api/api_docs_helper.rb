module API::APIDocsHelper
  def initial_menu_classes(side_displayed, show_decoration)
    classes = super
    classes << " api-docs"

    classes
  end
end
