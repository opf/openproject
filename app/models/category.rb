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

class Category < ApplicationRecord
  belongs_to :project
  belongs_to :assigned_to, class_name: "Principal"
  # Clears the deprecated single-category column; the join rows below carry the
  # actual assignments.
  has_many :work_packages, dependent: :nullify
  has_many :work_package_categories, dependent: :delete_all
  has_many :categorized_work_packages, through: :work_package_categories, source: :work_package

  validates :name,
            uniqueness: { scope: [:project_id], case_sensitive: false },
            length: { maximum: 255 }

  # validates that assignee is member of the issue category's project
  validates_each :assigned_to_id do |record, attr, value|
    if value && !(record.project.principals.map(&:id).include? value) # allow nil
      record.errors.add(attr, I18n.t(:error_must_be_project_member))
    end
  end

  alias :destroy_without_reassign :destroy

  # Destroy the category
  # If a category is specified, issues are reassigned to this category
  def destroy(reassign_to = nil)
    affected_work_package_ids = work_package_categories.pluck(:work_package_id)

    if reassign_to.is_a?(Category) && reassign_to.project == project
      reassign_work_packages_to(reassign_to)
    end

    destroy_without_reassign.tap do
      resync_legacy_category_ids(affected_work_package_ids)
    end
  end

  def <=>(other)
    name <=> other.name
  end

  def to_s; name end

  private

  def reassign_work_packages_to(other)
    # Work packages that already carry the target category would violate the join
    # table's uniqueness, so their row for this category is dropped rather than
    # moved over.
    already_assigned = WorkPackageCategory.where(category_id: other.id).select(:work_package_id)
    work_package_categories.where(work_package_id: already_assigned).delete_all

    work_package_categories.update_all(category_id: other.id, updated_at: Time.current)
  end

  # The deprecated work_packages.category_id column mirrors the alphabetically
  # first category of a work package. Both destroy paths above touch it bluntly
  # (`dependent: :nullify` clears it, the reassignment above overwrites it), which
  # is wrong for work packages that hold more than one category. Recompute it from
  # what is left in the join table. Can be dropped along with the column.
  def resync_legacy_category_ids(work_package_ids)
    return if work_package_ids.empty?

    WorkPackage.where(id: work_package_ids).update_all(<<~SQL.squish)
      category_id = (
        SELECT work_package_categories.category_id
        FROM work_package_categories
        INNER JOIN categories ON categories.id = work_package_categories.category_id
        WHERE work_package_categories.work_package_id = work_packages.id
        ORDER BY categories.name, categories.id
        LIMIT 1
      )
    SQL
  end
end
