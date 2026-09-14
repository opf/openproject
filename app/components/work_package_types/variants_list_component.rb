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

module WorkPackageTypes
  class VariantsListComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    FRAME_ID = "type-variants-list"

    def initialize(type:, query: nil)
      super()

      @type = type
      @query = query.presence
    end

    private

    attr_reader :type, :query

    # The base variant is the type itself, which the sibling tabs already configure, so only the
    # named ones are listed here.
    def named_variants = type.variants.non_default_variants.includes(:project)

    def variants
      @variants ||= begin
        scope = named_variants
        scope = scope.with_name_like(query) if query
        scope.in_display_order
      end
    end

    def any_variants? = named_variants.exists?

    # An empty section is dropped: a section explains what is in it.
    def sections
      @sections ||= variants
                      .partition { |variant| !variant.project_owned? }
                      .zip(%i[global_section project_specific_section])
                      .filter_map { |list, key| [key, list] if list.any? }
    end

    def filter_form_data
      {
        controller: "auto-submit",
        "auto-submit-delay-value": 300,
        turbo_frame: FRAME_ID,
        turbo_action: "replace"
      }
    end

    def add_variant_path = new_creation_wizard_types_path(type_id: type.id, back_url: variants_path)

    def menu_id(variant) = Types::VariantActionsComponent.menu_id(variant)

    # The menu's actions are reachable from the types index too, so each one has to be told to
    # come back here rather than to that list.
    def menu_src(variant)
      menu_type_variant_path(type_id: variant.type_id, id: variant.id, back_url: variants_path)
    end

    def variants_path = type_variants_path(type_id: type.id)

    def created_in(project)
      link = render(Primer::Beta::Link.new(href: project_settings_work_packages_types_path(project))) do
        project.name
      end

      t("types.edit.variants.created_in_html", project: link)
    end
  end
end
