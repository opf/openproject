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

class FormConfiguration
  class AttributeGroupRows
    EMPTY_GROUP_KEY = "__empty"

    def initialize(form)
      @form = form
    end

    def tuples
      groups = form.form_groups.loaded? ? form.form_groups : group_scope.includes(:query, :form_attributes)

      groups.map { tuple_of(it) }
    end

    def matches?(groups)
      groups.none? { query_changed?(it) } && signature_of(groups) == signature_of_rows
    end

    def store(groups)
      load_rows(groups)

      FormConfigurationGroup.acts_as_list_no_update([FormConfigurationAttribute]) do
        real_groups(groups).each.with_index(1) { |group, position| store_group(group, position) }
        deactivate_unplaced
        (@group_rows - @kept).each(&:destroy!)
      end

      WorkPackageTypes::FormConfiguration::EnsureAttributeRecordsService.new(form).call
      reset_associations
    end

    private

    attr_reader :form

    def tuple_of(group)
      key = group.default_key ? group.default_key.to_sym : group.label
      members = group.kind_query? ? [group.query] : group.form_attributes.map(&:key)

      [key, members, (group.label if group.default_key), group.id]
    end

    def reset_associations
      form.form_groups.reset
      form.form_attributes.reset
      form.custom_field_form_attributes.reset
      form.custom_fields.reset
    end

    def group_scope = FormConfigurationGroup.where(form_configuration_id: form.id).order(:position)

    def load_rows(groups)
      @group_rows = group_scope.to_a
      @kept = []
      @attribute_rows = FormConfigurationAttribute.where(form_configuration_id: form.id).to_a.index_by(&:key)
      @placed = Set.new
      @live_custom_field_ids = live_custom_field_ids(groups)
    end

    def real_groups(groups) = groups.reject { it.key.to_s == EMPTY_GROUP_KEY }

    def store_group(group, position)
      group_row = claim(group) || FormConfigurationGroup.new(form_configuration: form)
      replaced_query_id = group_row.query_id
      group_row.assign_attributes(position:, **naming(group), **kind_of(group))
      group_row.save!
      @kept << group_row
      ::Query.where(id: replaced_query_id).destroy_all if replaced_query_id && replaced_query_id != group_row.query_id

      place_attributes(group_row, group) unless group.is_a?(Type::QueryGroup)
    end

    def claim(group)
      available = @group_rows - @kept

      by_id = available.find { |group_row| group_row.id == group.record_id } if group.record_id
      by_id || available.find { |group_row| identity_of(group_row) == identity_of_group(group) }
    end

    def identity_of(group_row)
      group_row.default_key ? [:default, group_row.default_key] : [:custom, group_row.label]
    end

    def identity_of_group(group)
      default_key_of(group) ? [:default, default_key_of(group)] : [:custom, label_of(group)]
    end

    def naming(group)
      if default_key_of(group)
        { default_key: default_key_of(group), label: group.display_name.presence }
      else
        { default_key: nil, label: label_of(group) }
      end
    end

    def default_key_of(group)
      group.key.to_s if group.internal_key?
    end

    def label_of(group)
      label = group.display_name.presence || group.key.to_s.strip
      label.presence || I18n.t("types.edit.form_configuration.untitled_group")
    end

    def kind_of(group)
      return { kind: :attribute, query: nil } unless group.is_a?(Type::QueryGroup)

      group.query.save! if query_changed?(group)
      { kind: :query, query: group.query }
    end

    def place_attributes(group_row, group)
      position = 0

      group.attributes.each do |attribute|
        key = attribute.to_s
        next if @placed.include?(key) || !placeable?(key)

        attribute_row = @attribute_rows[key] || build_attribute_row(key)
        attribute_row.update!(group: group_row, position: position += 1)
        @placed << key
      end
    end

    def build_attribute_row(key)
      FormConfigurationAttribute.new(form_configuration: form, **FormConfigurationAttribute.reference_for(key))
    end

    def placeable?(key)
      custom_field_id = FormConfigurationAttribute.reference_for(key)[:custom_field_id]
      custom_field_id.nil? || @live_custom_field_ids.include?(custom_field_id)
    end

    def deactivate_unplaced
      @attribute_rows.each_value do |attribute_row|
        next unless attribute_row.active? && @placed.exclude?(attribute_row.key)

        attribute_row.update!(group: nil, position: nil)
      end
    end

    def live_custom_field_ids(groups)
      ids = groups.flat_map { |group| custom_field_ids_of(group) }
      WorkPackageCustomField.where(id: ids).pluck(:id).to_set
    end

    def custom_field_ids_of(group)
      return [] if group.is_a?(Type::QueryGroup)

      group.attributes.filter_map { FormConfigurationAttribute.reference_for(it)[:custom_field_id] }
    end

    def query_changed?(group)
      group.is_a?(Type::QueryGroup) && group.query.present? && (group.query.new_record? || group.query.changed?)
    end

    def signature_of(groups)
      real_groups(groups).map do |group|
        members = group.is_a?(Type::QueryGroup) ? [group.query&.id] : group.attributes.map(&:to_s)
        [naming(group), members]
      end
    end

    def signature_of_rows
      group_scope.includes(:form_attributes).map do |group|
        members = group.kind_query? ? [group.query_id] : group.form_attributes.map(&:key)

        [{ default_key: group.default_key, label: group.label }, members]
      end
    end
  end
end
