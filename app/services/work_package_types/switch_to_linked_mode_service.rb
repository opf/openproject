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
  # Switches one configuration aspect of a type to Linked. Serves both the
  # Independent -> Linked switch and re-pointing an existing link to a different
  # source ("change source"); both are the same write. The source-graph
  # invariants (present, global, not-self, acyclic) are the link record's own
  # validations.
  class SwitchToLinkedModeService
    def initialize(type:, aspect:)
      @type = type
      @aspect = aspect
    end

    def call(source:)
      link = @type.configuration_links.find_or_initialize_by(aspect: @aspect)
      link.source = source

      if link.save
        ServiceResult.success(result: @type)
      else
        # Return the rejected link so the caller can re-render the picker with its errors.
        ServiceResult.failure(result: link, errors: link.errors)
      end
    end

    private

    attr_reader :type, :aspect
  end
end
