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
  class DeleteDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    attr_reader :work_package

    def initialize(work_package:, back_url: nil)
      super
      @work_package = work_package
      @back_url = back_url
    end

    private

    def id = "wp-delete-dialog"

    def title
      I18n.t("work_packages.delete_dialog.title")
    end

    def heading
      I18n.t("work_packages.delete_dialog.heading")
    end

    def description
      I18n.t("work_packages.delete_dialog.description", name: work_package.to_s)
    end

    def confirmation_checkbox_text
      if has_descendants?
        I18n.t("work_packages.delete_dialog.confirm_descendants_deletion")
      else
        I18n.t("text_permanent_delete_confirmation_checkbox_label")
      end
    end

    def descendants
      @descendants ||= WorkPackage
        .joins("INNER JOIN work_package_hierarchies ON work_package_hierarchies.descendant_id = work_packages.id")
        .where(work_package_hierarchies: { ancestor_id: work_package.id })
        .where("work_package_hierarchies.generations > 0")
        .includes(:project, :type, :status)
        .order("work_package_hierarchies.generations ASC, work_packages.id ASC")
    end

    def has_descendants?
      descendants.any?
    end

    def cross_project_descendants?
      descendants.any? { |d| d.project != work_package.project }
    end

    def all_project_names
      names = descendants
        .filter_map(&:project)
        .uniq
        .reject { |p| p == work_package.project }
        .map(&:name)

      names
        .unshift(work_package.project.name)
        .join(", ")
    end

    def form_action
      helpers.work_packages_bulk_path(ids: [work_package.id], back_url: @back_url)
    end
  end
end
