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

# frozen_string_literal: true

module OpenProject::TypeSchemes
  module SetAttributesServicePatch
    private

    # Without an explicit type, core picks project.enabled_types.first. With a scheme, use its default.
    def assign_default_type
      super
      return unless ::TypeSchemes::Resolver.for_project(work_package.project)

      type = ::TypeSchemes::Resolver.allowed_types(work_package.project).first
      return if type.nil? || type == work_package.type

      work_package.type = type
      update_duration_to_one_day_for_milestones
      unify_milestone_dates
      reassign_status assignable_statuses
    end
  end
end
