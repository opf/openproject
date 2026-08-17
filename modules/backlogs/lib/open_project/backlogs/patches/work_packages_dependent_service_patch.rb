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

module OpenProject::Backlogs::Patches::WorkPackagesDependentServicePatch
  extend ActiveSupport::Concern

  included do
    prepend InstanceMethods
  end

  module InstanceMethods
    def copy_work_package(source_work_package, parent_id, user_cf_ids)
      return super unless source.backlogs_enabled?

      # Disable the acts_as_list callbacks so the position is carried over from
      # the source work package unchanged instead of being reappended.
      WorkPackage.acts_as_list_no_update { super }
    end

    def copy_work_package_attribute_overrides(source_work_package, parent_id, user_cf_ids)
      return super unless source.backlogs_enabled?

      super.merge(
        sprint_id: work_package_sprint_id(source_work_package),
        backlog_bucket_id: work_package_backlog_bucket_id(source_work_package),
        position: source_work_package.position
      )
    end

    def work_package_sprint_id(source_work_package)
      return unless source_work_package.sprint_id

      state.sprint_id_lookup&.[](source_work_package.sprint_id)
    end

    def work_package_backlog_bucket_id(source_work_package)
      return unless source_work_package.backlog_bucket_id

      state.backlog_bucket_id_lookup&.[](source_work_package.backlog_bucket_id)
    end
  end
end
