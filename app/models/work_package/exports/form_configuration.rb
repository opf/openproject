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

class WorkPackage::Exports::FormConfiguration
  include WorkPackage::Exports::Attributes

  AttributeGroup = Data.define(:key, :title, :parts)
  AttributesPart = Data.define(:entries)
  Entry          = Data.define(:label, :name)
  LongTextPart   = Data.define(:label, :markdown)
  QueryGroup     = Data.define(:key, :title, :query, :work_packages)

  def initialize(work_package)
    @work_package = work_package
  end

  def groups
    @groups ||= work_package.type_variant.attribute_groups.filter_map do |group|
      case group
      when Type::AttributeGroup then attribute_group(group)
      when Type::QueryGroup then query_group(group)
      end
    end
  end

  private

  attr_reader :work_package

  def attribute_group(group)
    parts = group_parts(group)
    return if parts.empty? && group.attributes.any?

    AttributeGroup.new(key: group.key, title: group.translated_key, parts:)
  end

  def query_group(group)
    prepare_query_group(group)
    QueryGroup.new(key: group.key, title: group.translated_key,
                   query: group.query, work_packages: group.query.results.work_packages)
  end

  def group_parts(group)
    group.active_members(work_package.project)
         .select { |form_key| show_attribute?(form_key) }
         .chunk_while { |a, b| !allowed_long_text_custom_field?(a) && !allowed_long_text_custom_field?(b) }
         .filter_map { |form_keys| build_part(form_keys) }
  end

  def build_part(form_keys)
    if allowed_long_text_custom_field?(form_keys.first)
      long_text_part(form_key_to_custom_field(form_keys.first))
    else
      entries = form_keys.flat_map { |form_key| form_key_to_column_entries(form_key.to_sym) }
      AttributesPart.new(entries:) if entries.any?
    end
  end

  def long_text_part(custom_field)
    custom_value = work_package.custom_field_values.find { |cv| cv.custom_field.id == custom_field.id }
    return if custom_value.nil?

    LongTextPart.new(label: custom_field.name, markdown: custom_value.value || "")
  end

  def show_attribute?(form_key)
    CustomField.custom_field_attribute?(form_key) || allowed_to_view_attribute?(work_package, form_key)
  end

  def allowed_long_text_custom_field?(form_key)
    return false unless CustomField.custom_field_attribute?(form_key)

    form_key_to_custom_field(form_key)&.formattable? || false
  end

  def form_key_to_custom_field(form_key)
    id = form_key.to_s.sub("custom_field_", "").to_i
    work_package.available_custom_fields.find { it.id == id }
  end

  def form_key_custom_field_to_column_entries(form_key)
    cf = form_key_to_custom_field(form_key)
    return [] if cf.nil? || cf.formattable?

    [Entry.new(label: cf.name || form_key.to_s, name: :"cf_#{cf.id}")]
  end

  def form_key_to_column_entries(form_key)
    return [] if form_key == :bcf_thumbnail
    return form_key_custom_field_to_column_entries(form_key) if CustomField.custom_field_attribute?(form_key)

    column_name = ::API::Utilities::PropertyNameConverter.to_ar_name(form_key, context: work_package).to_sym
    [column_entry(column_name)]
  end

  def column_entry(column_name)
    Entry.new(label: WorkPackage.human_attribute_name(column_label_attribute(column_name)), name: column_name)
  end

  def column_label_attribute(column_name)
    Queries::WorkPackages::StoredNames.offered_select(column_name).to_s
  end

  def prepare_query_group(group)
    group.query.filters.each do |filter|
      if filter.respond_to?(:has_templated_value?) && filter.has_templated_value?
        filter.values = [work_package.id]
      end
    end
  end
end
