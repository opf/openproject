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

    attr_reader :work_packages

    def initialize(work_packages:, back_url: nil)
      super
      @work_packages = work_packages
      @back_url = back_url
    end

    private

    def id = "wp-delete-dialog"

    def title
      I18n.t("work_packages.bulk_delete_dialog.title", count: total_count)
    end

    def heading
      I18n.t("work_packages.bulk_delete_dialog.heading", count: total_count)
    end

    def description
      if has_descendants?
        I18n.t("work_packages.bulk_delete_dialog.description_with_children")
      else
        I18n.t("work_packages.bulk_delete_dialog.description")
      end
    end

    def confirmation_checkbox_text
      if has_descendants?
        I18n.t("work_packages.bulk_delete_dialog.confirm_children_deletion")
      else
        I18n.t("text_permanent_delete_confirmation_checkbox_label")
      end
    end

    def total_count
      @total_count ||= work_packages.count + descendants_by_work_package.values.sum(&:size)
    end

    def multiple_projects?
      projects.size > 1
    end

    def project_names
      projects.map(&:name).join(", ")
    end

    def descendants_for(work_package)
      (descendants_by_work_package[work_package.id] || [])
        .reject { |child| work_packages.include?(child) }
    end

    def has_descendants?
      work_packages.any? { |wp| descendants_for(wp).any? }
    end

    def form_action
      helpers.work_packages_bulk_path(ids: work_packages.map(&:id), back_url: @back_url)
    end

    def projects
      @projects ||= begin
        all_work_packages = work_packages + descendants_by_work_package.values.flatten
        all_work_packages.filter_map(&:project).uniq
      end
    end

    def descendants_by_work_package
      @descendants_by_work_package ||= begin
        hierarchies = WorkPackageHierarchy
          .where(ancestor_id: work_packages.map(&:id))
          .where("generations > 0")
          .order(:generations, :descendant_id)

        descendant_records = WorkPackage
          .where(id: hierarchies.pluck(:descendant_id))
          .includes(:project, :type, :status)
          .index_by(&:id)

        hierarchies
          .group_by(&:ancestor_id)
          .transform_values { |rows| rows.filter_map { |r| descendant_records[r.descendant_id] } }
      end
    end
  end
end
