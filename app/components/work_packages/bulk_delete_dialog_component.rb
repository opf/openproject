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
  class BulkDeleteDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include WorkPackages::DeleteDialogs::Descendants

    attr_reader :work_packages

    def initialize(work_packages:, back_url: nil)
      super
      @work_packages = work_packages
      @back_url = back_url
    end

    private

    def id = DeleteDialogComponent::DIALOG_ID

    def i18n_scope = "work_packages.bulk_delete_dialog"

    def deletion_roots = work_packages.to_a

    def title
      return t_dialog("descendants_choice.heading") if has_descendants?

      t_dialog("title", count: total_count)
    end

    def heading
      return t_dialog("descendants_choice.heading") if has_descendants?

      t_dialog("heading", count: total_count)
    end

    def description
      return t_dialog("descendants_choice.question") if has_descendants?

      t_dialog("description")
    end

    def confirmation_checkbox_text
      t_dialog("confirm_deletion")
    end

    def total_count
      @total_count ||= work_package_ids.size + deleted_descendants.size
    end

    def form_action
      helpers.work_packages_bulk_path(ids: work_package_ids, delete_descendants: false, back_url: @back_url)
    end

    def confirm_delete_path
      helpers.confirm_delete_work_packages_bulk_path(ids: work_package_ids, back_url: @back_url)
    end

    def multiple_projects?
      projects.size > 1
    end

    def projects
      @projects ||= work_packages.filter_map(&:project).uniq
    end

    def work_package_ids
      @work_package_ids ||= work_packages.map(&:id)
    end
  end
end
