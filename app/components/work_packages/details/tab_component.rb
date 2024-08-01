# frozen_string_literal: true

class WorkPackages::Details::TabComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable
  include Redmine::MenuManager::MenuHelper

  attr_reader :tab, :work_package, :base_route

  def initialize(work_package:, base_route:, tab: :overview)
    super

    @work_package = work_package
    @tab = tab.to_sym
    @base_route = base_route
  end

  delegate :project, to: :work_package

  def menu = :work_package_split_view

  def menu_items
    @menu_items ||=
      Redmine::MenuManager
        .items(menu, nil)
        .root
        .children
        .select do |node|
        allowed_node?(node, User.current, project) && visible_node?(menu, node)
      end
  end

  def full_screen_tab
    if @tab.name == "overview"
      return :activity
    end

    @tab.name
  end
end
