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

class FormConfiguration < ApplicationRecord
  has_many :type_variants, dependent: :restrict_with_error, inverse_of: :form_configuration

  has_and_belongs_to_many :custom_fields, # rubocop:disable Rails/HasAndBelongsToMany
                          class_name: "WorkPackageCustomField",
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: "custom_field_id"

  serialize :attribute_groups, type: Array

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 255 }

  before_save :destroy_queries_dropped_from_groups
  after_destroy :destroy_group_queries

  def self.implicit_name(source)
    base = source.to_s.strip.presence
    available_name(base && I18n.t("forms.name.implicit", name: base))
  end

  def self.available_name(base)
    base = base.to_s.strip.presence || I18n.t("forms.name.fallback")
    return base unless exists?(["LOWER(name) = LOWER(?)", base])

    suffix = 2
    suffix += 1 while exists?(["LOWER(name) = LOWER(?)", "#{base} (#{suffix})"])
    "#{base} (#{suffix})"
  end

  private

  def destroy_queries_dropped_from_groups
    return unless attribute_groups_changed?

    ::Query.where(id: group_query_ids(attribute_groups_was) - group_query_ids(attribute_groups)).destroy_all
  end

  def destroy_group_queries
    ::Query.where(id: group_query_ids(attribute_groups)).destroy_all
  end

  def group_query_ids(groups)
    Array(groups).flat_map { |group| Array(group[1]) }
                 .filter_map { |key| ::Type::QueryGroup.query_attribute_id(key) }
  end
end
