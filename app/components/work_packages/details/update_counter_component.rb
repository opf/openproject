# frozen_string_literal: true

class WorkPackages::Details::UpdateCounterComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  attr_reader :work_package, :menu_name

  def initialize(work_package:, menu_name:)
    super

    @work_package = work_package
    @menu = find_menu_item(menu_name)
  end

  def call
    render Primer::Beta::Counter
      .new(count:,
           hide_if_zero: true,
           id: wrapper_key,
           test_selector: "wp-details-tab-component--#{@menu.name}-counter")
  end

  # We don't need a wrapper component, but wrap on the counter id
  def wrapped?
    true
  end

  def wrapper_key
    "wp-details-tab-#{@menu.name}-counter"
  end

  def render?
    @menu.present?
  end

  def count
    @menu
      .badge(work_package:)
      .to_i
  end

  def find_menu_item(menu_name)
    Redmine::MenuManager
        .items(:work_package_split_view, nil)
        .root
        .children
        .detect { |node| node.name.to_s == menu_name }
  end
end
