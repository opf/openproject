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

module CustomField::ProjectSpecificValues
  extend ActiveSupport::Concern

  included do
    enum :project_specific_value_restriction, { allow: "allow", block: "block" }, prefix: true, validate: { allow_nil: true }
    has_many :project_specific_value_restrictions, class_name: "CustomField::ProjectSpecificValueRestriction", dependent: nil
  end

  def usable_values_in(project)
    values = list? ? custom_options : hierarchy_root.descendants
    return values if project_specific_value_restriction.nil?

    listed = project_specific_value_restrictions.where(project:, restriction: project_specific_value_restriction)

    if list?
      usable_options(values, listed.select(:custom_option_id))
    else
      usable_items(values, listed.select(:hierarchy_item_id))
    end
  end

  private

  def usable_options(options, listed_ids)
    if project_specific_value_restriction_allow?
      options.where(id: listed_ids)
    else
      options.where.not(id: listed_ids)
    end
  end

  # An item is only usable if it and all of its ancestors are, so every item that is not usable
  # takes its whole subtree with it.
  def usable_items(items, listed_ids)
    unusable = project_specific_value_restriction_allow? ? items.where.not(id: listed_ids) : items.where(id: listed_ids)
    unusable_subtrees = CustomField::Hierarchy::ItemHierarchy.where(ancestor_id: unusable.select(:id))

    items.where.not(id: unusable_subtrees.select(:descendant_id))
  end
end
