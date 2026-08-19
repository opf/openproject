# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Component for rendering the relations tab content of a work package
#
# This includes:
# - Controls for adding new relations if the user has permission
# - Related work packages grouped by relation type (follows, precedes, blocks, etc.)
# - Child work packages
class WorkPackageRelationsTab::IndexComponent < ApplicationComponent
  FRAME_ID = "work-package-relations-tab-content"
  ADD_RELATION_ACTION_MENU = "add-relation-action-menu"
  ADD_RELATION_SUB_MENU = "add-relation-sub-menu"
  ADD_CHILD_ACTION_MENU = "add-child-action-menu"
  I18N_NAMESPACE = "work_package_relations_tab"

  ADD_CHILD_MENU_TYPES = [
    "new_child",
    Relation::TYPE_CHILD
  ].freeze

  FIRST_LEVEL_RELATION_MENU_TYPES = [
    Relation::TYPE_RELATES,
    Relation::TYPE_FOLLOWS,
    Relation::TYPE_PRECEDES,
    *ADD_CHILD_MENU_TYPES,
    Relation::TYPE_PARENT
  ].freeze

  SECOND_LEVEL_RELATION_MENU_TYPES = [
    Relation::TYPE_DUPLICATES,
    Relation::TYPE_DUPLICATED,
    Relation::TYPE_BLOCKS,
    Relation::TYPE_BLOCKED,
    Relation::TYPE_INCLUDES,
    Relation::TYPE_PARTOF,
    Relation::TYPE_REQUIRES,
    Relation::TYPE_REQUIRED
  ].freeze

  include ApplicationHelper
  include OpPrimer::ComponentHelpers
  include Turbo::FramesHelper
  include OpTurbo::Streamable

  attr_reader :relations_mediator, :relation_to_scroll_to

  delegate :work_package,
           :visible_children,
           :ghost_children,
           :relation_groups,
           to: :relations_mediator

  # Initialize the component with required data
  #
  # @param work_package [WorkPackage] The work package whose relations are being displayed
  # @param relation_to_scroll_to [Relation, WorkPackage, nil] Optional relation or child to scroll to when rendering
  def initialize(work_package: nil, relation_to_scroll_to: nil)
    super()

    @relations_mediator = WorkPackageRelationsTab::RelationsMediator.new(work_package:)
    @relation_to_scroll_to = relation_to_scroll_to
  end

  def self.wrapper_key
    FRAME_ID
  end

  private

  def should_render_add_child?
    return false if work_package.milestone?

    allowed_to?(:manage_subtasks)
  end

  def should_render_add_parent?
    allowed_to?(:manage_subtasks)
  end

  def should_render_add_relations?
    allowed_to?(:manage_work_package_relations)
  end

  def allowed_to?(permission)
    helpers.current_user.allowed_in_project?(permission, work_package.project)
  end

  def should_render_create_button?
    should_render_add_child? || should_render_add_parent? || should_render_add_relations?
  end

  def render_relation_group(title:, relation_group:, &)
    render(border_box_container(
             padding: :condensed,
             data: { test_selector: "op-relation-group-#{relation_group.type}" }
           )) do |border_box|
      if relation_group.type.child? && should_render_add_child?
        render_children_header(border_box, title, relation_group.count)
      else
        render_header(border_box, title, relation_group.count)
      end

      render_items(border_box, relation_group.all_relation_items, &)
    end
  end

  def render_header(border_box, title, count)
    border_box.with_header(py: 3) do
      concat render(Primer::Beta::Text.new(mr: 2, font_size: :normal, font_weight: :bold)) { title }
      concat render(Primer::Beta::Counter.new(count:, round: true, scheme: :primary))
    end
  end

  def render_children_header(border_box, title, count) # rubocop:disable Metrics/AbcSize
    border_box.with_header(py: 3) do
      flex_layout(justify_content: :space_between, align_items: :center) do |header|
        header.with_column(mr: 2) do
          concat render(Primer::Beta::Text.new(mr: 2, font_size: :normal, font_weight: :bold)) { title }
          concat render(Primer::Beta::Counter.new(count:, round: true, scheme: :primary))
        end
        header.with_column do
          render(Primer::Alpha::ActionMenu.new(menu_id: ADD_CHILD_ACTION_MENU)) do |menu|
            menu.with_show_button do |button|
              button.with_leading_visual_icon(icon: :plus)
              button.with_trailing_action_icon(icon: :"triangle-down")
              t("work_package_relations_tab.label_add_child_button")
            end

            render_add_relations_menu_items(menu, ADD_CHILD_MENU_TYPES)
          end
        end
      end
    end
  end

  # Renders the menu items for the add relations action menu
  #
  # @param menu [Primer::Alpha::ActionMenu] The action menu component to render the items in
  # @param relation_types [Array<String>] The relation types to render menu items for
  def render_add_relations_menu_items(menu, relation_types)
    relation_types
      .filter { |relation_type| can_add_relation?(relation_type) }
      .each { |relation_type| render_add_relation_menu_item(menu, relation_type) }
  end

  def render_add_relation_menu_item(menu, relation_type)
    menu.with_item(
      label: label(relation_type),
      href: new_relation_path(relation_type),
      test_selector: new_button_test_selector(relation_type),
      content_arguments: {
        data: { turbo_stream: true }
      }
    ) do |item|
      item.with_description.with_content(description(relation_type))
    end
  end

  def can_add_relation?(relation_type)
    case relation_type
    when "new_child"
      should_render_add_child? && allowed_to?(:add_work_packages)
    when Relation::TYPE_CHILD
      should_render_add_child?
    when Relation::TYPE_PARENT
      should_render_add_parent?
    when *Relation::TYPES.keys
      should_render_add_relations?
    else
      false
    end
  end

  def label(relation_type)
    label_key =
      if Relation::TYPES.key?(relation_type)
        "#{Relation::TYPES[relation_type][:name]}_singular"
      else
        relation_type
      end

    label = t("#{I18N_NAMESPACE}.relations.#{label_key}")
    label.upcase_first
  end

  def description(relation_type)
    I18n.t("#{I18N_NAMESPACE}.relations.#{relation_type}_description")
  end

  def render_items(border_box, relation_items)
    relation_items.each do |relation_item|
      relation = relation_item.relation || relation_item.related
      visibility = relation_item.visibility
      border_box.with_row(
        test_selector: row_test_selector(relation, visibility),
        data: data_attribute(relation)
      ) do
        yield(relation_item)
      end
    end
  end

  def data_attribute(item)
    if scroll_to?(item)
      {
        controller: "work-packages--relations-tab--scroll",
        "work-packages--relations-tab--scroll-target": "scrollToRow"
      }
    end
  end

  def scroll_to?(item)
    relation_to_scroll_to \
      && item.id == relation_to_scroll_to.id \
      && item.instance_of?(relation_to_scroll_to.class)
  end

  def new_relation_path(relation_type)
    case relation_type
    when "new_child"
      new_project_work_packages_dialog_path(work_package.project, parent_id: work_package.id)
    when Relation::TYPE_CHILD, Relation::TYPE_PARENT
      new_work_package_hierarchy_relation_path(work_package, relation_type:)
    when *Relation::TYPES.keys
      new_work_package_relation_path(work_package, relation_type:)
    else
      raise ArgumentError, "Invalid relation type: #{relation_type}"
    end
  end

  def new_button_test_selector(relation_type)
    "op-new-relation-button-#{relation_type}"
  end

  def row_test_selector(item, visibility)
    related_work_package_id = find_related_work_package_id(item)
    "op-relation-row-#{visibility}-#{related_work_package_id}"
  end

  def find_related_work_package_id(item)
    if item.is_a?(Relation)
      item.from_id == work_package.id ? item.to_id : item.from_id
    else
      item.id
    end
  end
end
