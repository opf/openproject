# frozen_string_literal: true

# -- copyright
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
# ++

module Queries::WorkPackages::Filter
  class BacklogInboxFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    include Queries::Filters::Shared::BooleanFilter

    def available?
      if project.present?
        User.current.allowed_in_project?(:view_sprints, project)
      else
        User.current.allowed_in_any_project?(:view_sprints)
      end
    end

    def dependency_class
      "::API::V3::Queries::Schemas::BooleanFilterDependencyRepresenter"
    end

    def where
      if filtering_for_true?
        "work_packages.sprint_id IS NULL AND work_packages.backlog_bucket_id IS NULL"
      else
        "work_packages.sprint_id IS NOT NULL OR work_packages.backlog_bucket_id IS NOT NULL"
      end
    end

    def human_name
      I18n.t("query_fields.backlog_inbox")
    end
  end
end
