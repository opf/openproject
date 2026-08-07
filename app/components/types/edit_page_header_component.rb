# frozen_string_literal: true

# -- copyright
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
# ++

module Types
  class EditPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include TabsHelper

    def initialize(type:, tabs: nil, routes: nil)
      super
      @type = type
      @tabs = tabs
      @routes = routes || ::WorkPackageTypes::TypeRoutes.for(type)
    end

    def breadcrumb_items
      [*@routes.breadcrumb_root_items,
       *parent_breadcrumb_item,
       breadcrumb_leaf]
    end

    private

    # Inside a project the parent is administered somewhere the reader cannot go, so it
    # names the family as plain text rather than a link that would refuse them.
    def parent_breadcrumb_item
      return [] if @type.parent.nil?

      href = @routes.parent_details
      [href ? { href:, text: @type.parent.name } : @type.parent.name]
    end

    def breadcrumb_leaf
      return @type.own_name unless @type.variant?

      t("types.edit.breadcrumb_variant", name: @type.own_name)
    end
  end
end
