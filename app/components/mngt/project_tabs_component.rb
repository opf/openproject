# frozen_string_literal: true

class Mngt::ProjectTabsComponent < ApplicationComponent
  def initialize(project:, current_menu_item: nil)
    super()
    @project = project
    @current_menu_item = current_menu_item&.to_sym
  end

  def tab_items
    @tab_items ||= begin
      root = Redmine::MenuManager.items(:project_menu, @project)
      root.children.select do |item|
        !item.partial && !(item.condition && !item.condition.call(@project))
      end
    end
  rescue StandardError
    []
  end

  def tab_url(item)
    params = item.url(@project).dup
    params[item.param] ||= @project.identifier
    params
  end

  def tab_caption(item)
    item.caption(@project)
  end

  def tab_icon(item)
    item.icon(@project)
  end

  def active?(item)
    @current_menu_item == item.name
  end
end
