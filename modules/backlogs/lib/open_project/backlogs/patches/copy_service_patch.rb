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

module OpenProject::Backlogs::Patches::CopyServicePatch
  extend ActiveSupport::Concern

  included do
    prepend InstanceMethods
  end

  module InstanceMethods
    def clean_settings_attributes!(settings)
      # There can be only one project sharing with all projects.
      if settings["sprint_sharing"] == Projects::SprintSharing::SHARE_ALL_PROJECTS ||
         !EnterpriseToken.allows_to?(:sprint_sharing)
        settings.delete("sprint_sharing")
      end

      super
    end

    def after_perform(call)
      super.tap do |result_call|
        next unless source.backlogs_enabled?
        next unless result_call.result&.persisted?

        result_call.result.done_statuses = source.done_statuses
        result_call.result.backlog_excluded_types = source.backlog_excluded_types
      end
    end
  end
end
