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

module ResourceAllocations
  # The body of the work package allocations dialog: the allocation progress
  # summary and one row per allocation. Streamable so the dialog content can be
  # refreshed after an allocation changes. Allocations whose principal is not
  # visible to the current user are still listed, but anonymised.
  class ListComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(project:, work_package:, allocations:, visible_principal_ids:, overbooked_ids: Set.new)
      super

      @project = project
      @work_package = work_package
      @allocations = allocations
      @visible_principal_ids = visible_principal_ids
      @overbooked_ids = overbooked_ids
    end

    private

    attr_reader :project, :work_package, :allocations, :visible_principal_ids, :overbooked_ids

    def visible_principal?(allocation)
      allocation.principal_id.nil? || visible_principal_ids.include?(allocation.principal_id)
    end

    def overbooked?(allocation)
      overbooked_ids.include?(allocation.id)
    end

    def editable?
      return @editable if defined?(@editable)

      @editable = User.current.allowed_in_project?(:allocate_user_resources, project)
    end
  end
end
