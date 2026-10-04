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

module WikiPages
  class ShowPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper

    def initialize(page:, project:, editable:)
      super
      @page = page
      @project = project
      @editable = editable
    end

    def lock_data
      if @page.protected?
        { label: t(:button_unlock), icon: :unlock, protected: 0 }
      else
        { label: t(:button_lock), icon: :lock, protected: 1 }
      end
    end

    def show_edit?
      User.current.allowed_in_project?(:edit_wiki_pages, @project) && @page.current_version?
    end

    def show_rollback?
      User.current.allowed_in_project?(:edit_wiki_pages, @project) && !@page.current_version?
    end

    def show_atom_link?
      @project.present? && @project.module_enabled?("activity")
    end

    def export_atom_link
      url_for(
        controller: "/activities",
        action: "index",
        id: @project,
        show_wiki_edits: 1,
        apply: true,
        key: User.current.rss_key,
        format: "atom"
      )
    end

    def export_markdown_link
      url_for(
        version: @page.version,
        id: @page,
        format: "markdown"
      )
    end
  end
end
