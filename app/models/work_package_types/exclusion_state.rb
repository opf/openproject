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
  # The elements this variant does not show.
  #  - own: what this variant itself drops
  #  - effective: the union over the whole chain
  #
  # An element in effective but not in own was excluded further up the chain, which is what
  # #excluded_by_source? answers: this variant cannot reach that exclusion to undo it.
  #
  # Nil for an aspect the variant owns: there is nothing to exclude from. Nil too for an aspect
  # that cannot be narrowed at all, which a variant inherits whole or owns outright.
  ExclusionState = Data.define(:variant, :own, :effective) do
    def self.for(variant, aspect)
      return unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)
      return unless variant.linked?(aspect)

      column = :"#{TypeVariant.validated_excludable_aspect(aspect)}_excluded_elements"

      new(
        variant:,
        own: variant.public_send(column).map(&:to_s),
        effective: variant.effective_excluded_elements(aspect).map(&:to_s)
      )
    end

    def excluded?(key)
      effective.include?(key.to_s)
    end

    def excluded_by_source?(key)
      excluded?(key) && own.exclude?(key.to_s)
    end
  end
end
