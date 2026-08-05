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

module WorkPackage::Categories
  extend ActiveSupport::Concern

  included do
    # Deprecated single-category column, kept in sync with the first category
    # (see #update_legacy_category_field). Can be dropped once all subsystems
    # read categories instead.
    belongs_to :category, class_name: "Category", optional: true

    has_many :work_package_categories, dependent: :delete_all
    # Ordered by name, matching every other category listing (see
    # Project#categories). The order also decides which category is mirrored
    # into the deprecated category_id column, so #category and #categories.first
    # can never disagree.
    has_many :categories,
             -> { order(:name) },
             through: :work_package_categories, source: :category

    scope :with_category, ->(category_id) {
      where(id: WorkPackageCategory.where(category_id:).select(:work_package_id))
    }

    # Work packages with no category at all. Reading the join table rather than
    # the deprecated column keeps this correct once a work package can hold
    # categories that the single column cannot represent.
    scope :without_category, -> {
      where.not(id: WorkPackageCategory.select(:work_package_id))
    }

    # Must be registered before `save_journals` (WorkPackage::Journalized) so
    # that the journal snapshot sees the current category set in the database.
    after_save :persist_category_associations

    # Stores in memory the values that will replace the written categories.
    # This is used by the contracts/services flow in order to do checks and
    # validations before persisting any actual data to the database.
    attr_accessor :category_ids_replacements
  end

  # Categories the work package can be assigned to. Unlike versions, categories
  # are never shared with or inherited by other projects, so this is exactly the
  # project's own set. Name-ordered, matching #categories.
  def assignable_categories
    project&.categories || Category.none
  end

  # The category_ids_replacements accessor behaves according to these rules:
  # - when nil (the default) - leave the existing associations untouched
  # - when [] - clear the association
  # - when [<category ids>] - replace the existing set with exactly these
  # Consequently, nil vs. non-nil tells us whether an override was requested
  # at all.
  def override_categories? = !category_ids_replacements.nil?

  # List of categories, but takes into account a pending override that was not
  # written yet.
  #
  # By precedence:
  #   * category_ids_replacements
  #   * pending category_id change
  #   * actual written categories
  #
  # Name-ordered like the association, so #effective_categories.first is always
  # the category that a save would mirror into category_id.
  def effective_categories
    if category_ids_replacements.nil?
      return category_id_changed? ? Array(category) : categories
    end

    Category.where(id: category_ids_replacements).order(:name).to_a
  end

  private

  # Two paths feed the categories association:
  #   * an explicit override (category_ids_replacements was set) takes
  #     precedence and replaces the whole set.
  #   * otherwise, a plain change to category_id (the legacy single-category
  #     path) is mirrored into the association so both stay consistent.
  #
  # Writing to category_id will be removed after all subsystems start using
  # categories instead.
  def persist_category_associations
    if override_categories?
      replace_categories(category_ids_replacements)
      update_legacy_category_field
    elsif saved_change_to_category_id?
      replace_categories(Array(category_id))
    end

    clear_category_override
  end

  # The override is consumed by exactly one save. Left in place, it would be
  # re-applied by any later save of the same instance, clobbering category
  # changes made in between.
  def clear_category_override
    self.category_ids_replacements = nil
  end

  # Keeps the deprecated single category_id column in sync with the first
  # category, so code still reading category_id sees a sensible value.
  # Can be dropped once the category_id column is removed.
  def update_legacy_category_field
    # Read the association fresh: replace_categories only resets it when the set
    # actually changed, so a cached target could otherwise mirror a stale first
    # category.
    categories.reset
    new_category_id = categories.first&.id

    update_columns(category_id: new_category_id) unless category_id == new_category_id
  end

  # Resets any cached values. Necessary because we do insert_all.
  def reset_category_associations
    work_package_categories.reset
    categories.reset
  end

  # Sets the work package's category associations to exactly the given
  # category_ids.
  def replace_categories(category_ids)
    existing = work_package_categories.pluck(:category_id)

    to_remove = existing - category_ids
    to_add    = category_ids - existing

    return if to_remove.empty? && to_add.empty?

    apply_category_changes(to_remove, to_add)
    reset_category_associations
  end

  # remove associations that are not present in the new list of categories and
  # add those that were not already there
  def apply_category_changes(to_remove, to_add)
    work_package_categories.where(category_id: to_remove).delete_all if to_remove.any?
    work_package_categories.insert_all(to_add.map { |cid| { category_id: cid } }) if to_add.any?
  end
end
