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
  # Switches one configuration aspect of a variant to Linked. Serves both the
  # Independent -> Linked switch and re-pointing an existing link to a different
  # source ("change source"); both are the same write. The source-graph
  # invariants (present, global, not-self, acyclic) are the link record's own
  # validations.
  class SwitchToLinkedModeService
    def initialize(variant:, aspect:)
      @variant = variant
      @aspect = aspect
    end

    def call(source:)
      @variant.public_send(:"#{TypeVariant.validated_configuration_aspect(@aspect)}_source=", source)

      if @variant.save
        ServiceResult.success(result: @variant)
      else
        ServiceResult.failure(result: @variant, errors: @variant.errors)
      end
    end

    private

    attr_reader :variant, :aspect
  end
end
