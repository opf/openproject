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

    def initialize(type:, variant: nil, tabs: nil, additional_breadcrumb_items: [], title: nil)
      super
      @type = type
      @variant = variant
      @tabs = tabs
      @additional_breadcrumb_items = additional_breadcrumb_items
      @title = title
    end

    def title
      @title || variant_or_type_name
    end

    def breadcrumb_items
      [*helpers.variant_scope_breadcrumb_roots,
       *variant_breadcrumb_item,
       *own_breadcrumb_item,
       *@additional_breadcrumb_items]
    end

    private

    def named_variant? = @variant.is_a?(TypeVariant) && !@variant.is_default_variant?

    def variant_or_type_name
      return @type.name unless named_variant?

      t("types.edit.breadcrumb_variant", name: @variant.variant_name)
    end

    # Link back to the type's own page when we are on a named variant, since the crumb below
    # then shows the variant's name rather than the type's.
    def variant_breadcrumb_item
      return [] unless named_variant?

      [{ href: variant_breadcrumb_href, text: @type.name }]
    end

    # The type's own screen is administration's, so from a project this leads to that project's
    # list of types instead.
    def variant_breadcrumb_href
      return edit_type_details_path(type_id: @type.id) if scope_project.nil?

      project_settings_work_packages_types_path(scope_project)
    end

    def scope_project = helpers.variant_scope_project

    def own_breadcrumb_item
      text = variant_or_type_name
      return [text] if @additional_breadcrumb_items.blank?

      [{ href: edit_type_details_path(**(@variant&.path_args || { type_id: @type.id })), text: }]
    end
  end
end
