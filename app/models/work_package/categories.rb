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

module WorkPackage::Categories
  extend ActiveSupport::Concern

  included do
    has_many :work_package_categories, dependent: :delete_all
    has_many :categories, -> { order(:id) }, through: :work_package_categories, source: :category

    before_save :mirror_category_replacements_to_category_id
    after_save :persist_category_associations

    # nil leaves the categories untouched, [] removes all of them,
    # and a list of ids replaces the current set.
    attr_accessor :category_ids_replacements
  end

  def override_categories? = !category_ids_replacements.nil?

  def first_category_id_of(category_ids)
    category_ids = category_ids.uniq
    return category_ids.first if category_ids.size <= 1

    Category.where(id: category_ids).alphabetical.pick(:id)
  end

  private

  def mirror_category_replacements_to_category_id
    return unless override_categories?

    self.category_id = first_category_id_of(category_ids_replacements)
  end

  def persist_category_associations
    if override_categories?
      replace_categories(category_ids_replacements)
    elsif saved_change_to_category_id?
      replace_categories(Array(category_id))
    end

    self.category_ids_replacements = nil
  end

  def replace_categories(category_ids)
    work_package_categories.where.not(category_id: category_ids).delete_all
    work_package_categories.insert_all(category_ids.uniq.map { { category_id: it } }) if category_ids.any?

    work_package_categories.reset
    categories.reset
  end
end
