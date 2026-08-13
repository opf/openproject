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
  # The contents of one variant's row, as listed on the type's variants tab and inside the
  # type's group on the types index. The row's action menu is not part of this: it hangs off
  # the surrounding list item, and each list points it back at itself.
  class VariantRowComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    # @param caption [String, nil] muted text after the name, telling rows apart where the
    #   list mixes variants with other records.
    def initialize(variant:, caption: nil)
      super()

      @variant = variant
      @caption = caption
    end

    private

    attr_reader :variant, :caption

    def variant_path = edit_type_details_path(**variant.path_args)

    # An administrator sees every project's variants side by side, so an unattributed row
    # would be indistinguishable from a global one.
    def owner_label = t("types.index.owned_by", project: variant.project.name)
  end
end
