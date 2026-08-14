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

    def initialize(type:)
      super()

      @type = type
    end

    private

    attr_reader :type

    # The base variant is the type itself, which the sibling tabs already configure, so only the
    # named ones are listed here.
    def variants
      @variants ||= type.variants.non_default_variants.in_display_order
    end

    def title = TypeVariant.model_name.human(count: 2)

    def variant_path(variant) = edit_type_details_path(**variant.path_args)

    def add_variant_path = new_creation_wizard_types_path(type_id: type.id)

    def menu_id(variant) = Types::VariantActionsComponent.menu_id(variant)

    def menu_src(variant) = menu_type_variant_path(type_id: variant.type_id, id: variant.id)
  end
end
