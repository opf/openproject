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

module Projects::Copy
  class SprintsDependentService < Dependency
    def self.human_name
      I18n.t("projects.copy.sprints")
    end

    def source_count
      source.sprints.count
    end

    protected

    def copy_dependency(*)
      sprint_id_map = {}

      source.sprints.each do |source_sprint|
        attributes = source_sprint.attributes.dup.except("id", "project_id", "created_at", "updated_at")
        sprint = target.sprints.create!(attributes)
        sprint_id_map[source_sprint.id] = sprint.id
      end

      state.sprint_id_lookup = sprint_id_map
    end
  end
end
