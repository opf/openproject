# frozen_string_literal: true

module API::APIDocsHelper
  def initial_menu_classes(side_displayed, show_decoration)
    class_names(super, "api-docs")
  end
end
