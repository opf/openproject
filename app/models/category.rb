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

class Category < ApplicationRecord
  belongs_to :project
  belongs_to :assigned_to, class_name: "Principal"
  has_many :work_packages, dependent: :nullify
  has_many :work_package_categories, dependent: :delete_all
  has_many :categorized_work_packages, through: :work_package_categories, source: :work_package

  scope :alphabetical, -> { order(arel_table[:name].lower, arel_table[:id]) }

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
    if reassign_to && reassign_to.is_a?(Category) && reassign_to.project == project
      reassign_work_package_categories_to(reassign_to)
      WorkPackage.where(category_id: id).update_all(category_id: reassign_to.id)
    end
    destroy_without_reassign
  end

  def <=>(other)
    name <=> other.name
  end

  def to_s; name end

  private

  def reassign_work_package_categories_to(other)
    self.class.connection.execute(self.class.sanitize_sql_array([<<~SQL.squish, other.id, id]))
      INSERT INTO work_package_categories (work_package_id, category_id, created_at, updated_at)
      SELECT work_package_id, ?, NOW(), NOW()
      FROM work_package_categories
      WHERE category_id = ?
      ON CONFLICT (work_package_id, category_id) DO NOTHING
    SQL
  end
end
