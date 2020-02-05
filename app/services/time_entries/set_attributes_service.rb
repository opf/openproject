#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module TimeEntries
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(attributes)
      super

      ##
      # Update project context if moving time entry
      if no_project_or_context_changed?
        model.project = model.work_package&.project
      end
    end

    def set_default_attributes(*)
      set_default_user
      set_default_activity
      set_default_hours
    end

    def set_default_user
      change_by_system do
        model.user = user
      end
    end

    def set_default_activity
      model.activity ||= TimeEntryActivity.default
    end

    def set_default_hours
      model.hours = nil if model.hours&.zero?
    end

    def no_project_or_context_changed?
      !model.project ||
        (model.work_package && model.work_package_id_changed? && !model.project_id_changed?)
    end
  end
end
