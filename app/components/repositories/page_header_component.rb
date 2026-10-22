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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Repositories
  class PageHeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(repository:, empty: false, path: nil, rev: nil, project: nil)
      super
      @project = project
      @repository = repository
      @path = path
      @rev = rev
      @empty = empty
    end

    def breadcrumb_items
      [
        project_breadcrumb,
        repository_breadcrumb,
        *path_breadcrumbs
      ]
    end

    def project_breadcrumb
      {
        href: project_overview_path(@project.id),
        text: @project.name
      }
    end

    def repository_breadcrumb
      {
        href: url_for(action: "show", project_id: @project.id, repo_path: nil, rev: @rev),
        text: t("repositories.named_repository", vendor_name: @repository.class.vendor_name)
      }
    end

    def path_breadcrumbs
      dirs = @path.to_s.split("/").compact_blank
      link_path = ""
      dirs.each_with_index.map do |dir, index|
        link_path = File.join(link_path, dir)

        if index == dirs.size - 1
          dir
        else
          {
            href: url_for(
              action: "show",
              project_id: @project.id,
              repo_path: to_path_param(link_path),
              rev: @rev
            ),
            text: dir
          }
        end
      end
    end
  end
end
