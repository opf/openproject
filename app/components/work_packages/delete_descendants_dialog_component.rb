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

module WorkPackages
  class DeleteDescendantsDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include WorkPackages::DeleteDialogs::Descendants

    DIALOG_ID = "wp-delete-descendants-dialog"

    attr_reader :work_package

    def initialize(work_package:, back_url: nil)
      super
      @work_package = work_package
      @back_url = back_url
    end

    private

    def id = DIALOG_ID

    def i18n_scope = "work_packages.delete_dialog"

    def deletion_roots = [work_package]

    def title
      t_dialog("title")
    end

    def heading
      t_dialog("heading")
    end

    def description
      t_dialog("description", name: work_package.to_s)
    end

    def confirmation_checkbox_text
      t_dialog(deleted_descendants.any? ? "confirm_descendants_deletion" : "confirm_deletion")
    end

    def cross_project_descendants?
      deleted_descendants.any? { |d| d.project != work_package.project }
    end

    def all_project_links
      projects = deleted_descendants
        .filter_map(&:project)
        .uniq
        .reject { |p| p == work_package.project }
        .unshift(work_package.project)

      link_to_projects(projects)
    end

    def form_action
      helpers.work_packages_bulk_path(ids: [work_package.id], delete_descendants: true, back_url: @back_url)
    end
  end
end
