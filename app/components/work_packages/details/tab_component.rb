# frozen_string_literal: true

class WorkPackages::Details::TabComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable
  include Redmine::MenuManager::MenuHelper

  attr_reader :tab, :work_package

  def initialize(work_package:, tab: :overview)
    @work_package = work_package
    @tab = tab.to_sym
  end

  delegate :project, to: :work_package

  def menu = :work_package_split_view

  def menu_items
    @menu_items ||= begin
      Redmine::MenuManager
        .items(menu, nil)
        .root
        .children
        .select do |node|
        allowed_node?(node, User.current, project) && visible_node?(menu, node)
      end
    end
  end
end
