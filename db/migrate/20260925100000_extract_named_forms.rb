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

  class MigratedGroup < ActiveRecord::Base
    self.table_name = "form_configuration_groups"
  end

  class MigratedAttribute < ActiveRecord::Base
    self.table_name = "form_configuration_attributes"
  end

  class MigratedQuery < ActiveRecord::Base
    self.table_name = "queries"
  end

  class MigratedCustomField < ActiveRecord::Base
    self.table_name = "custom_fields"
    self.inheritance_column = nil
  end

  MIGRATED_CLASSES = [MigratedTypeVariant, MigratedGroup, MigratedAttribute, MigratedQuery, MigratedCustomField].freeze

  ATTRIBUTE_KIND = "attribute"
  QUERY_KIND = "query"
  EMPTY_SENTINEL = "__empty"
  QUERY_MEMBER = /\Aquery_(\d+)\z/
  CUSTOM_FIELD_MEMBER = /\Acustom_field_(\d+)\z/
  DEFAULT_GROUPS = {
    people: %w[assignee responsible],
    estimates_and_progress: %w[estimated_time remaining_time percentage_done spent_time
                               story_points allocated_time allocated_principals],
    details: %w[priority sprint backlog_bucket target_versions category project_phase date],
    other: %w[position],
    costs: %w[costs_by_type labor_costs material_costs overall_costs budget]
  }.freeze

  def self.query_group_id(members)
    members.first.to_s[QUERY_MEMBER, 1]&.to_i if members.one?
  end

  def self.reference_for(key)
    if (custom_field_id = key.to_s[CUSTOM_FIELD_MEMBER, 1])
      { custom_field_id: custom_field_id.to_i, attribute_key: nil }
    else
      { custom_field_id: nil, attribute_key: key.to_s }
    end
  end

  def self.member_keys(group)
    MigratedAttribute
      .where(form_configuration_group_id: group.id)
      .order(:position)
      .map { it.custom_field_id ? "custom_field_#{it.custom_field_id}" : it.attribute_key }
  end

  def self.group_identity(group)
    group.default_key ? group.default_key.to_sym : group.label
  end

  def self.group_members(group)
    group.kind == QUERY_KIND ? [:"query_#{group.query_id}"] : member_keys(group)
  end

  def self.translated_default(key)
    translation_key = ::TypeVariant.default_groups[key.to_sym]
    translation_key ? I18n.t(translation_key) : key.to_s
  end

  def self.next_untitled_label(seen_labels)
    base_name = I18n.t("types.edit.form_configuration.untitled_group")
    candidate = base_name
    suffix = 2

    while seen_labels.include?(candidate)
      candidate = "#{base_name} #{suffix}"
      suffix += 1
    end

    candidate
  end

  class FormRows
    attr_reader :groups

    def initialize(form_id)
      @form_id = form_id
      @groups = []
      @member_counts = Hash.new(0)
    end

    def create_group!(**)
      MigratedGroup.create!(form_configuration_id: @form_id, position: groups.size + 1, **).tap { groups << it }
    end

    def place!(group, key)
      MigratedAttribute.create!(form_configuration_id: @form_id,
                                form_configuration_group_id: group.id,
                                position: @member_counts[group.id] += 1,
                                **ExtractNamedForms.reference_for(key))
    end
  end

  def up
    # Create the separate table structure for forms and link it to variants
    create_form_configurations

    # For each type and variant currently present, create a new form object
    create_a_form_for_each_owner

    # Variants inherit the base type's form
    point_linked_variants_at_their_base_form

    # Copy required attributes for Variants inheriting the form previously
    flatten_required_attributes

    # Temporary: Link custom_field_types to the new form
    rekey_custom_fields_types

    # Create separate records for groups/sections of a form
    create_group_tables

    # Convert the content: attribute_groups from the type/variant to the form records
    # active fields and custom fields as individual records
    convert_forms

    # Fixing an inconsistency:
    # A custom field could be "active" in the form through the join table
    # but not added to any group (often used in specs, for example)
    # We report on them here, but leave them out of the migrated forms
    report_custom_fields_left_off_the_forms

    # Since custom fields are now explicit rows, we no longer need the join table
    drop_table :custom_fields_types

    execute <<~SQL.squish
      UPDATE type_variants
      SET linked_aspects = array_remove(linked_aspects, 'form_configuration')
    SQL

    # Remove attribute_groups and related columns
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
    MIGRATED_CLASSES.each(&:reset_column_information)

    say_with_time "Store each form as groups and attributes" do
      owners = MigratedTypeVariant.where.not(linked("type_variants"))
      in_configurable_batches(owners) { |batch| batch.each_record { |row| convert(row) } }
    end
  end

  def convert(row)
    I18n.with_locale(Setting.default_language) { convert_owner!(row) }
  rescue ActiveRecord::StatementInvalid => e
    raise Unconvertible, "form_configurations ##{row.form_configuration_id} (type_variants ##{row.id}): #{e.message}"
  end

  def convert_owner!(row)
    if attribute_groups_of(row).blank?
      write_defaults(row)
    else
      Conversion.new(self, row).run!
    end
  end

  def attribute_groups_of(row)
    row.attribute_groups
  rescue ActiveRecord::SerializationTypeMismatch => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not an array (#{e.message})"
  rescue Psych::Exception => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not parseable (#{e.message})"
  end

  def write_defaults(row)
    rows = FormRows.new(row.form_configuration_id)

    default_groups_of(row).each do |key, members|
      group = rows.create_group!(kind: ATTRIBUTE_KIND, default_key: key.to_s)
      members.each { rows.place!(group, it) }
    end
  end

  def default_groups_of(row)
    milestone = select_value("SELECT is_milestone FROM types WHERE id = #{row.type_id}")
    custom_fields = active_custom_field_ids(row.form_configuration_id).sort.map { "custom_field_#{it}" }

    DEFAULT_GROUPS
      .merge(other: DEFAULT_GROUPS[:other] + custom_fields)
      .then { milestone ? it.except(:estimates_and_progress) : it }
  end

  def active_custom_field_ids(form_id)
    select_values("SELECT custom_field_id FROM custom_fields_types WHERE form_configuration_id = #{form_id}").map(&:to_i)
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
    MIGRATED_CLASSES.each(&:reset_column_information)

    MigratedTypeVariant.where.not(linked("type_variants")).find_each do |row|
      row.update_column(:attribute_groups, legacy_tuples(row.form_configuration_id))
    end
  end

  def legacy_tuples(form_id)
    MigratedGroup.where(form_configuration_id: form_id).order(:position).map do |group|
      [self.class.group_identity(group), self.class.group_members(group), (group.label if group.default_key)].compact
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
    def initialize(migration, row)
      @migration = migration
      @row = row
      @rows = FormRows.new(row.form_configuration_id)
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
      prune_required_attributes!
      verify!
    end

    private

    attr_reader :migration, :row, :rows

    def form_id = row.form_configuration_id

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
        next false if query_id.nil? || MigratedQuery.exists?(query_id)

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
      if MigratedGroup.exists?(query_id:)
        query_id = copy_shared_query!(key, query_id)
        @expected[rows.groups.size][1] = [:"query_#{query_id}"]
      end

      rows.create_group!(kind: QUERY_KIND, query_id:, **group_naming(key, display_name))
    end

    def copy_shared_query!(key, query_id)
      copy = MigratedQuery.create!(MigratedQuery.find(query_id).attributes.except("id", "created_at", "updated_at"))
      log("copied query_#{query_id} as query_#{copy.id} for group #{key.inspect}: shared with another configuration")
      copy.id
    end

    def convert_attribute_group!(key, members, display_name)
      group = rows.create_group!(kind: ATTRIBUTE_KIND, **group_naming(key, display_name))
      members.each { |member| place_member!(group, member) }
    end

    def group_naming(key, display_name)
      if key.is_a?(Symbol) && rows.groups.none? { it.default_key == key.to_s }
        { default_key: key.to_s, label: display_name.presence }
      elsif key.is_a?(Symbol)
        label = ExtractNamedForms.translated_default(key)
        log("default group #{key.inspect} listed twice; kept the second as custom group #{label.inspect}")
        { default_key: nil, label: }
      else
        label = display_name.presence || key.to_s.strip
        label = next_untitled_label if label.blank?
        { default_key: nil, label: }
      end
    end

    def next_untitled_label
      ExtractNamedForms.next_untitled_label(@seen_labels).tap { |untitled| @seen_labels << untitled }
    end

    def label_of(group)
      group.label.presence || ExtractNamedForms.translated_default(group.default_key)
    end

    def place_member!(group, member)
      key = member.to_s

      if @placed_keys.include?(key)
        log("dropped repeated attribute #{key} from group #{label_of(group).inspect}")
        drop_expected_member!(group, key)
        return
      end

      custom_field_id = ExtractNamedForms.reference_for(key)[:custom_field_id]
      if custom_field_id && @existing_custom_field_ids.exclude?(custom_field_id)
        log("dropped #{key} from group #{label_of(group).inspect}: custom field no longer exists")
        @dropped_keys << key
        drop_expected_member!(group, key)
        return
      end

      @placed_keys << key
      rows.place!(group, key)
    end

    def drop_expected_member!(group, key)
      index = rows.groups.index(group)
      @expected[index][1].delete_at(@expected[index][1].index(key)) if @expected[index]&.dig(1)&.include?(key)
    end

    def existing_custom_field_ids(tuples)
      ids = tuples.flat_map do |_, members, _|
        members.filter_map { |member| ExtractNamedForms.reference_for(member)[:custom_field_id] }
      end

      MigratedCustomField.where(id: ids, type: "WorkPackageCustomField").pluck(:id).to_set
    end

    def prune_required_attributes!
      return if @dropped_keys.empty?

      remaining = Array(row[:required_attributes]).map(&:to_s) - @dropped_keys
      row.update_column(:required_attributes, remaining)
    end

    def verify!
      actual = rows.groups.map do |group|
        [ExtractNamedForms.group_identity(group), ExtractNamedForms.group_members(group)]
      end

      return if actual == @expected

      unconvertible!("verification failed, expected #{@expected.inspect} but stored #{actual.inspect}")
    end

    def log(message)
      migration.say("form_configurations ##{form_id} (type_variants ##{row.id}): #{message}")
    end

    def unconvertible!(reason)
      raise Unconvertible, "form_configurations ##{form_id} (type_variants ##{row.id}): #{reason}"
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
        ExtractNamedForms.translated_default(key)
      else
        label = display_name.presence || key.to_s.strip
        label.presence || ExtractNamedForms.next_untitled_label(@seen_labels).tap { |untitled| @seen_labels << untitled }
      end
    end
  end
end
