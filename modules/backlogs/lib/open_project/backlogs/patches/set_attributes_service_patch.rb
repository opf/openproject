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

module OpenProject::Backlogs::Patches::SetAttributesServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    private

    def set_attributes(attributes)
      super

      if moved_to_another_project? && model.backlog_bucket_id
        model.change_by_system do
          model.backlog_bucket = nil
        end
      end

      if moved_to_project_that_has_no_access_to_sprint?
        model.change_by_system do
          model.sprint = nil
        end
      end

      clear_conflicting_sprint_or_bucket
    end

    # A work package may only have either a sprint *or* a bucket assigned. Not both at the
    # same time. Instead of throwing a validation error and making the user resolve it,
    # we resolve it implicitly: whichever attribute was just changed wins, the other is cleared.
    def clear_conflicting_sprint_or_bucket
      # No conflict to resolve? Abort.
      return unless model.backlog_bucket_id? && model.sprint_id?

      if model.sprint_id_changed?
        model.backlog_bucket = nil
      else
        model.sprint = nil
      end
    end

    def moved_to_another_project?
      work_package.persisted? && work_package.project_id_changed?
    end

    def moved_to_project_that_has_no_access_to_sprint?
      moved_to_another_project? &&
        work_package.sprint_id &&
        !work_package.sprint.visible_to?(work_package.project)
    end
  end
end
