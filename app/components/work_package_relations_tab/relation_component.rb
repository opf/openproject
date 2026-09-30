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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageRelationsTab::RelationComponent < ApplicationComponent
  include ApplicationHelper
  include OpPrimer::ComponentHelpers

  attr_reader :relation_item, :editable

  delegate :closest?, :relation, :visible?, :work_package, to: :relation_item

  # Checks if the relation or child work package is visible to the current user
  #
  # @param relation_item [WorkPackageRelationsTab::RelationsMediator::RelationItem] The relation item to display
  # @param editable [Boolean] Whether the relation can be edited
  def initialize(relation_item:, editable: true)
    super()

    @relation_item = relation_item
    @editable = editable
  end

  def related_work_package
    relation_item.related
  end

  def editable? = editable

  private

  def hierarchy_relationship? = relation.nil?

  def should_render_edit_option?
    # Children and parent can not be edited as it's not a relation.
    !hierarchy_relationship? && allowed_to_manage_relations?
  end

  def should_render_action_menu?
    return false unless editable?

    if hierarchy_relationship?
      allowed_to_manage_subtasks?
    else
      allowed_to_manage_relations?
    end
  end

  def allowed_to_manage_subtasks?
    helpers.current_user.allowed_in_project?(:manage_subtasks, work_package.project) &&
      helpers.current_user.allowed_in_project?(:manage_subtasks, related_work_package.project)
  end

  def allowed_to_manage_relations?
    helpers.current_user.allowed_in_project?(:manage_work_package_relations, work_package.project)
  end

  def should_display_description?
    return false if hierarchy_relationship?

    relation.description.present?
  end

  def lag_present?
    relation.lag.present? && relation.lag != 0
  end

  def should_display_dates_row?
    hierarchy_relationship? || relation.follows? || relation.precedes?
  end

  def follows?
    return false if hierarchy_relationship?

    relation.relation_type_for(work_package) == Relation::TYPE_FOLLOWS
  end

  def precedes?
    return false if hierarchy_relationship?

    relation.relation_type_for(work_package) == Relation::TYPE_PRECEDES
  end

  def edit_path
    if hierarchy_relationship?
      raise NotImplementedError, "Children and parent relationships are not editable"
    else
      edit_work_package_relation_path(work_package, relation)
    end
  end

  def destroy_path
    if hierarchy_relationship?
      work_package_hierarchy_relation_path(work_package, related_work_package)
    else
      work_package_relation_path(work_package, relation)
    end
  end

  def lag_as_text(lag)
    "#{I18n.t('work_package_relations_tab.lag.subject')}: #{I18n.t('datetime.distance_in_words.x_days', count: lag)}"
  end

  def action_menu_test_selector
    "op-relation-row-#{related_work_package.id}-action-menu"
  end

  def edit_button_test_selector
    "op-relation-row-#{related_work_package.id}-edit-button"
  end

  def delete_button_test_selector
    "op-relation-row-#{related_work_package.id}-delete-button"
  end
end
