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

require Rails.root.join("db/migrate/migration_utils/utils")

class ExtractNamedForms < ActiveRecord::Migration[8.1]
  include Migration::Utils

  class Unconvertible < StandardError; end

  class MigratedTypeVariant < ActiveRecord::Base
    self.table_name = "type_variants"
    serialize :attribute_groups, type: Array
  end

  EMPTY_SENTINEL = "__empty"
  QUERY_MEMBER = /\Aquery_(\d+)\z/

  def self.query_group_id(members)
    members.first.to_s[QUERY_MEMBER, 1]&.to_i if members.one?
  end

  def up
    create_form_configurations
    create_a_form_for_each_owner
    point_linked_variants_at_their_base_form
    flatten_required_attributes
    rekey_custom_fields_types
    create_group_tables
    convert_forms
    report_custom_fields_left_off_the_forms
    drop_table :custom_fields_types

    execute <<~SQL.squish
      UPDATE type_variants
      SET linked_aspects = array_remove(linked_aspects, 'form_configuration')
    SQL

    remove_form_columns_from_type_variants
  end

  def down
    restore_form_columns_on_type_variants
    restore_attribute_groups
    restore_form_custom_fields_types
    drop_table :form_configuration_attributes
    drop_table :form_configuration_groups
    restore_custom_fields_types

    remove_foreign_key :type_variants, column: :form_configuration_id
    remove_index :type_variants, :form_configuration_id
    remove_column :type_variants, :form_configuration_id

    drop_table :form_configurations
  end

  private

  def linked(table) = "'form_configuration' = ANY(#{table}.linked_aspects)"

  def create_form_configurations
    create_table :form_configurations do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :form_configurations, "lower(name)", unique: true, name: "index_form_configurations_on_LOWER_name"
    add_column :type_variants, :form_configuration_id, :bigint
  end

  def create_a_form_for_each_owner
    say_with_time "Create a form for each variant that owns its form configuration" do
      execute <<~SQL.squish
        UPDATE type_variants
        SET form_configuration_id = nextval('form_configurations_id_seq')
        WHERE NOT #{linked('type_variants')}
      SQL

      execute <<~SQL.squish
        INSERT INTO form_configurations (id, name, created_at, updated_at)
        SELECT id,
               CASE WHEN position = 1 THEN name ELSE name || ' (' || position || ')' END,
               NOW(),
               NOW()
        FROM (
          SELECT v.form_configuration_id AS id,
                 named.name,
                 ROW_NUMBER() OVER (PARTITION BY LOWER(named.name) ORDER BY v.id) AS position
          FROM type_variants v
          INNER JOIN types t ON t.id = v.type_id
          CROSS JOIN LATERAL (
            SELECT CASE
                     WHEN v.is_default_variant THEN t.name
                     ELSE t.name || ': ' || v.variant_name
                   END || ' form' AS name
          ) named
          WHERE NOT #{linked('v')}
        ) owners
      SQL
    end
  end

  def point_linked_variants_at_their_base_form
    say_with_time "Point inheriting variants at their type's form" do
      execute <<~SQL.squish
        UPDATE type_variants v
        SET form_configuration_id = base.form_configuration_id
        FROM type_variants base
        WHERE base.type_id = v.type_id
          AND base.is_default_variant
          AND #{linked('v')}
      SQL
    end

    change_column_null :type_variants, :form_configuration_id, false
    add_index :type_variants, :form_configuration_id
    add_foreign_key :type_variants, :form_configurations, column: :form_configuration_id, on_delete: :restrict
  end

  def flatten_required_attributes
    say_with_time "Give inheriting variants their own required attributes" do
      execute <<~SQL.squish
        UPDATE type_variants v
        SET required_attributes = ARRAY(
          SELECT required.attribute
          FROM unnest(base.required_attributes) WITH ORDINALITY AS required(attribute, position)
          WHERE NOT required.attribute = ANY(v.form_configuration_excluded_elements)
          ORDER BY required.position
        )
        FROM type_variants base
        WHERE base.type_id = v.type_id
          AND base.is_default_variant
          AND #{linked('v')}
      SQL
    end

    execute <<~SQL.squish
      UPDATE type_variants
      SET form_configuration_excluded_elements = '{}'
      WHERE NOT #{linked('type_variants')}
    SQL
  end

  def rekey_custom_fields_types
    add_column :custom_fields_types, :form_configuration_id, :bigint

    say_with_time "Move active custom fields from variants to their forms" do
      execute <<~SQL.squish
        DELETE FROM custom_fields_types cft
        USING type_variants v
        WHERE v.id = cft.type_variant_id
          AND #{linked('v')}
      SQL

      execute <<~SQL.squish
        UPDATE custom_fields_types cft
        SET form_configuration_id = v.form_configuration_id
        FROM type_variants v
        WHERE v.id = cft.type_variant_id
      SQL
    end

    remove_index_on :custom_fields_types, "custom_fields_types_unique", %w[custom_field_id type_variant_id]
    remove_foreign_key :custom_fields_types, column: :type_variant_id
    remove_index :custom_fields_types, :type_variant_id
    remove_column :custom_fields_types, :type_variant_id

    change_column_null :custom_fields_types, :form_configuration_id, false
    add_index :custom_fields_types, :form_configuration_id
    add_index :custom_fields_types, %i[custom_field_id form_configuration_id],
              unique: true,
              name: "custom_fields_types_unique"
    add_foreign_key :custom_fields_types, :form_configurations, column: :form_configuration_id, on_delete: :cascade
  end

  def create_group_tables # rubocop:disable Metrics/AbcSize
    create_table :form_configuration_groups do |t|
      t.references :form_configuration, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.string :kind, null: false
      t.string :default_key
      t.string :label
      t.references :query, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.timestamps

      t.index %i[id form_configuration_id], unique: true, name: "index_form_configuration_groups_on_id_and_owner"
      t.index %i[form_configuration_id default_key], unique: true, where: "default_key IS NOT NULL",
                                                     name: "index_form_configuration_groups_on_owner_and_default_key"
      t.check_constraint "kind IN ('attribute', 'query')", name: "form_configuration_groups_kind"
      t.check_constraint "(kind = 'query') = (query_id IS NOT NULL)", name: "form_configuration_groups_query_matches_kind"
      t.check_constraint "default_key IS NOT NULL OR label IS NOT NULL", name: "form_configuration_groups_named"
      t.unique_constraint %i[form_configuration_id position], deferrable: :deferred,
                                                              name: "form_configuration_groups_position"
    end

    create_table :form_configuration_attributes do |t|
      t.references :form_configuration, null: false, foreign_key: { on_delete: :cascade }
      t.references :form_configuration_group
      t.integer :position
      t.references :custom_field, foreign_key: { on_delete: :cascade }
      t.string :attribute_key
      t.timestamps

      t.index %i[form_configuration_id custom_field_id], unique: true, where: "custom_field_id IS NOT NULL",
                                                         name: "index_form_configuration_attributes_on_owner_and_custom_field"
      t.index %i[form_configuration_id attribute_key], unique: true, where: "attribute_key IS NOT NULL",
                                                       name: "index_form_configuration_attributes_on_owner_and_key"
      t.check_constraint "(custom_field_id IS NULL) <> (attribute_key IS NULL)",
                         name: "form_configuration_attributes_one_reference"
      t.check_constraint "(form_configuration_group_id IS NULL) = (position IS NULL)",
                         name: "form_configuration_attributes_placement"
      t.unique_constraint %i[form_configuration_group_id position], deferrable: :deferred,
                                                                    name: "form_configuration_attributes_position"
    end

    add_foreign_key :form_configuration_attributes, :form_configuration_groups,
                    column: %i[form_configuration_group_id form_configuration_id],
                    primary_key: %i[id form_configuration_id],
                    name: "fk_form_configuration_attributes_group_owner"
  end

  def convert_forms
    [MigratedTypeVariant, TypeVariant, FormConfiguration, FormConfigurationGroup, FormConfigurationAttribute]
      .each(&:reset_column_information)

    say_with_time "Store each form as groups and attributes" do
      owners = MigratedTypeVariant.where.not(linked("type_variants"))
      in_configurable_batches(owners) { |batch| batch.each_record { |row| convert(row) } }
    end
  end

  def convert(row)
    form = FormConfiguration.find(row.form_configuration_id)

    I18n.with_locale(Setting.default_language) do
      FormConfiguration.transaction { convert_owner!(form, row) }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    raise Unconvertible, "form_configurations ##{row.form_configuration_id} (type_variants ##{row.id}): #{e.message}"
  end

  def convert_owner!(form, row)
    if attribute_groups_of(row).blank?
      generate_defaults!(form, TypeVariant.find(row.id))
    else
      Conversion.new(self, form, row).run!
    end
  end

  def attribute_groups_of(row)
    row.attribute_groups
  rescue ActiveRecord::SerializationTypeMismatch => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not an array (#{e.message})"
  rescue Psych::Exception => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not parseable (#{e.message})"
  end

  def generate_defaults!(form, variant)
    result = WorkPackageTypes::FormConfiguration::GenerateDefaultsService
               .new(form, from: variant, custom_field_ids: active_custom_field_ids(form))
               .call
    return if result.success?

    raise Unconvertible, "type_variants ##{variant.id}: defaults not generated (#{result.errors.full_messages.to_sentence})"
  end

  def active_custom_field_ids(form)
    select_values("SELECT custom_field_id FROM custom_fields_types WHERE form_configuration_id = #{form.id}").map(&:to_i)
  end

  def report_custom_fields_left_off_the_forms
    rows = select_rows(<<~SQL.squish)
      SELECT cft.form_configuration_id, cft.custom_field_id
      FROM custom_fields_types cft
      WHERE NOT EXISTS (
        SELECT 1 FROM form_configuration_attributes fca
        WHERE fca.form_configuration_id = cft.form_configuration_id
          AND fca.custom_field_id = cft.custom_field_id
          AND fca.form_configuration_group_id IS NOT NULL
      )
    SQL

    rows.each do |form_id, custom_field_id|
      say "form_configurations ##{form_id}: custom_field_#{custom_field_id} was active but in no group; now inactive"
    end
  end

  def restore_form_custom_fields_types
    create_table :custom_fields_types, id: false do |t|
      t.bigint :custom_field_id, null: false
      t.bigint :form_configuration_id, null: false
    end

    execute <<~SQL.squish
      INSERT INTO custom_fields_types (custom_field_id, form_configuration_id)
      SELECT custom_field_id, form_configuration_id
      FROM form_configuration_attributes
      WHERE custom_field_id IS NOT NULL
        AND form_configuration_group_id IS NOT NULL
    SQL

    add_index :custom_fields_types, :form_configuration_id
    add_index :custom_fields_types, %i[custom_field_id form_configuration_id],
              unique: true,
              name: "custom_fields_types_unique"
    add_foreign_key :custom_fields_types, :form_configurations, column: :form_configuration_id, on_delete: :cascade
  end

  def restore_attribute_groups
    [MigratedTypeVariant, FormConfiguration].each(&:reset_column_information)

    MigratedTypeVariant.where.not(linked("type_variants")).find_each do |row|
      form = FormConfiguration.find(row.form_configuration_id)
      row.update_column(:attribute_groups, legacy_tuples(form))
    end
  end

  def legacy_tuples(form)
    FormConfiguration::AttributeGroupRows.new(form).tuples.map do |key, members, display_name, _|
      members = members.map { |member| member.is_a?(Query) ? :"query_#{member.id}" : member }
      [key, members, display_name].compact
    end
  end

  def remove_form_columns_from_type_variants
    remove_foreign_key :type_variants, column: :form_configuration_source_id
    remove_index :type_variants, :form_configuration_source_id
    remove_column :type_variants, :form_configuration_source_id
    remove_column :type_variants, :attribute_groups
  end

  def restore_form_columns_on_type_variants
    add_column :type_variants, :attribute_groups, :text
    add_reference :type_variants, :form_configuration_source,
                  foreign_key: { to_table: :type_variants, on_delete: :restrict },
                  index: true

    execute <<~SQL.squish
      UPDATE type_variants v
      SET linked_aspects = array_append(v.linked_aspects, 'form_configuration'),
          form_configuration_source_id = base.id
      FROM type_variants base
      WHERE base.type_id = v.type_id
        AND base.is_default_variant
        AND NOT v.is_default_variant
        AND base.form_configuration_id = v.form_configuration_id
    SQL
  end

  def restore_custom_fields_types
    add_column :custom_fields_types, :type_variant_id, :bigint
    remove_index_on :custom_fields_types, "custom_fields_types_unique", %w[custom_field_id form_configuration_id]

    execute <<~SQL.squish
      INSERT INTO custom_fields_types (custom_field_id, form_configuration_id, type_variant_id)
      SELECT cft.custom_field_id, cft.form_configuration_id, v.id
      FROM custom_fields_types cft
      INNER JOIN type_variants v ON v.form_configuration_id = cft.form_configuration_id
      WHERE NOT #{linked('v')}
    SQL

    execute "DELETE FROM custom_fields_types WHERE type_variant_id IS NULL"

    remove_foreign_key :custom_fields_types, column: :form_configuration_id
    remove_index :custom_fields_types, :form_configuration_id
    remove_column :custom_fields_types, :form_configuration_id

    change_column_null :custom_fields_types, :type_variant_id, false
    add_index :custom_fields_types, :type_variant_id
    add_index :custom_fields_types, %i[custom_field_id type_variant_id],
              unique: true,
              name: "custom_fields_types_unique"
    add_foreign_key :custom_fields_types, :type_variants, column: :type_variant_id, on_delete: :cascade
  end

  # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
  class Conversion
    def initialize(migration, form, row)
      @migration = migration
      @form = form
      @row = row
      @dropped_keys = []
      @placed_keys = Set.new
    end

    def run!
      tuples = drop_missing_query_groups(parse_tuples!)
      @seen_labels = tuples.filter_map do |key, _, display_name|
        (display_name.presence || key.to_s.strip).presence if key.is_a?(String)
      end
      @expected = LegacyExpectation.new(tuples, @seen_labels.dup).call
      @existing_custom_field_ids = existing_custom_field_ids(tuples)
      tuples.each { |tuple| convert_tuple!(tuple) }
      WorkPackageTypes::FormConfiguration::ReconcileAttributesService.new(form).call
      prune_required_attributes!
      verify!
    end

    private

    attr_reader :migration, :form, :row

    def parse_tuples!
      row.attribute_groups.filter_map do |tuple|
        unless tuple.is_a?(Array) && tuple.size.between?(2, 3)
          unconvertible!("group #{tuple.inspect} is not a [key, members] tuple")
        end
        key, members, display_name = tuple
        unless key.nil? || key.is_a?(String) || key.is_a?(Symbol)
          unconvertible!("group key #{key.inspect} is neither a string nor a symbol")
        end
        unconvertible!("members of #{key.inspect} are not an array") unless members.is_a?(Array)
        members.each do |member|
          next if member.is_a?(String) || member.is_a?(Symbol)

          unconvertible!("member #{member.inspect} of #{key.inspect} is neither a string nor a symbol")
        end
        next if key.to_s == EMPTY_SENTINEL

        [key, members, display_name]
      end
    end

    def drop_missing_query_groups(tuples)
      tuples.reject do |key, members, _|
        query_id = ExtractNamedForms.query_group_id(members)
        next false if query_id.nil? || Query.exists?(query_id)

        log("dropped query group #{key.inspect} referencing missing query_#{query_id}")
        true
      end
    end

    def convert_tuple!(tuple)
      key, members, display_name = tuple
      query_id = ExtractNamedForms.query_group_id(members)

      if query_id
        convert_query_group!(key, query_id, display_name)
      else
        convert_attribute_group!(key, members, display_name)
      end
    end

    def convert_query_group!(key, query_id, display_name)
      if FormConfigurationGroup.exists?(query_id:)
        query_id = rebuild_shared_query!(key, query_id)
        @expected[form.form_groups.count][1] = [:"query_#{query_id}"]
      end

      form.form_groups.create!(kind: FormConfigurationGroup::QUERY, query_id:, **group_naming(key, display_name))
    end

    def rebuild_shared_query!(key, query_id)
      result = WorkPackageTypes::FormConfiguration::EmbeddedQueryBuilder.rebuild(query: Query.find(query_id),
                                                                                 user: User.system)
      if result.failure?
        unconvertible!("query_#{query_id} of group #{key.inspect} is shared with another configuration " \
                       "and could not be rebuilt (#{result.errors.full_messages.to_sentence})")
      end

      query = result.result
      query.save! unless query.persisted?
      log("rebuilt query_#{query_id} as query_#{query.id} for group #{key.inspect}: shared with another configuration")
      query.id
    end

    def convert_attribute_group!(key, members, display_name)
      group = form.form_groups.create!(kind: FormConfigurationGroup::ATTRIBUTE, **group_naming(key, display_name))
      members.each { |member| place_member!(group, member) }
    end

    def group_naming(key, display_name)
      if key.is_a?(Symbol) && form.form_groups.where(default_key: key.to_s).none?
        { default_key: key.to_s, label: display_name.presence }
      elsif key.is_a?(Symbol)
        label = translated_default(key)
        log("default group #{key.inspect} listed twice; kept the second as custom group #{label.inspect}")
        { default_key: nil, label: }
      else
        label = display_name.presence || key.to_s.strip
        label = next_untitled_label if label.blank?
        { default_key: nil, label: }
      end
    end

    def next_untitled_label
      Type::FormGroup.next_untitled_key(@seen_labels).tap { |untitled| @seen_labels << untitled }
    end

    def translated_default(key)
      translation_key = TypeVariant.default_groups[key]
      translation_key ? I18n.t(translation_key) : key.to_s
    end

    def place_member!(group, member)
      key = member.to_s

      if @placed_keys.include?(key)
        log("dropped repeated attribute #{key} from group #{group.translated_label.inspect}")
        drop_expected_member!(group, key)
        return
      end

      reference = FormConfigurationAttribute.reference_for(key)
      if reference[:custom_field_id] && @existing_custom_field_ids.exclude?(reference[:custom_field_id])
        log("dropped #{key} from group #{group.translated_label.inspect}: custom field no longer exists")
        @dropped_keys << key
        drop_expected_member!(group, key)
        return
      end

      @placed_keys << key
      form.form_attributes.create!(group:, position: group.members.count + 1, **reference)
    end

    def drop_expected_member!(group, key)
      index = form.form_groups.reload.index(group)
      @expected[index][1].delete_at(@expected[index][1].index(key)) if @expected[index]&.dig(1)&.include?(key)
    end

    def existing_custom_field_ids(tuples)
      ids = tuples.flat_map do |_, members, _|
        members.filter_map { |member| FormConfigurationAttribute.reference_for(member)[:custom_field_id] }
      end

      WorkPackageCustomField.where(id: ids).pluck(:id).to_set
    end

    def prune_required_attributes!
      return if @dropped_keys.empty?

      remaining = Array(row[:required_attributes]).map(&:to_s) - @dropped_keys
      row.update_column(:required_attributes, remaining)
    end

    def verify!
      actual = form.form_groups.reload.map do |group|
        key = group.default_key ? group.default_key.to_sym : group.label
        members = group.query? ? [:"query_#{group.query_id}"] : group.members.map(&:key)
        [key, members]
      end

      return if actual == @expected

      unconvertible!("verification failed, expected #{@expected.inspect} but stored #{actual.inspect}")
    end

    def log(message)
      migration.say("form_configurations ##{form.id} (type_variants ##{row.id}): #{message}")
    end

    def unconvertible!(reason)
      raise Unconvertible, "form_configurations ##{form.id} (type_variants ##{row.id}): #{reason}"
    end
  end

  class LegacyExpectation
    def initialize(tuples, seen_labels)
      @tuples = tuples
      @seen_labels = seen_labels
      @seen_default_keys = Set.new
    end

    def call
      @tuples.map do |key, members, display_name|
        query_id = ExtractNamedForms.query_group_id(members)
        [identity(key, display_name), query_id ? [:"query_#{query_id}"] : members.map(&:to_s)]
      end
    end

    private

    def identity(key, display_name)
      if key.is_a?(Symbol) && @seen_default_keys.add?(key)
        key
      elsif key.is_a?(Symbol)
        translation_key = TypeVariant.default_groups[key]
        translation_key ? I18n.t(translation_key) : key.to_s
      else
        label = display_name.presence || key.to_s.strip
        label.presence || Type::FormGroup.next_untitled_key(@seen_labels).tap { |untitled| @seen_labels << untitled }
      end
    end
  end
end
