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

    def initialize(type:, tabs: nil, additional_breadcrumb_items: [], title: nil)
      super
      @type = type
      @tabs = tabs
      @additional_breadcrumb_items = additional_breadcrumb_items
      @title = title
    end

    def title
      @title || @type.own_name
    end

    def breadcrumb_items
      [{ href: admin_index_path, text: t("label_administration") },
       { href: admin_settings_work_packages_general_path, text: t(:label_work_package_plural) },
       { href: types_path, text: t(:label_type_plural) },
       *parent_breadcrumb_item,
       *type_breadcrumb_item,
       *@additional_breadcrumb_items]
    end

    private

    def parent_breadcrumb_item
      return [] if @type.parent.nil?

      [{ href: edit_type_details_path(type_id: @type.parent_id), text: @type.parent.name }]
    end

    def type_breadcrumb_item
      text = breadcrumb_leaf
      return [text] if @additional_breadcrumb_items.blank?

      [{ href: edit_type_details_path(type_id: @type.id), text: }]
    end

    def breadcrumb_leaf
      return @type.own_name unless @type.variant?

      t("types.edit.breadcrumb_variant", name: @type.own_name)
    end
  end
end
