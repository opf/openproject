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

class BackfillFormConfigurationRecords < ActiveRecord::Migration[8.1]
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
    owners = MigratedTypeVariant.where.not("'form_configuration' = ANY(linked_aspects)")

    in_configurable_batches(owners) do |batch|
      batch.each_record { |row| convert(row) }
    end
  end

  def down
    execute "DELETE FROM form_configuration_attributes"
    execute "DELETE FROM form_configuration_groups"
  end

  private

  def convert(row)
    variant = TypeVariant.find(row.id)
    return if variant.form_groups.exists? || variant.form_attributes.exists?

    I18n.with_locale(Setting.default_language) do
      TypeVariant.transaction { convert_owner!(variant, row) }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    raise Unconvertible, "type_variants ##{row.id}: #{e.message}"
  end

  def convert_owner!(variant, row)
    if attribute_groups_of(row).blank?
      generate_defaults!(variant)
    else
      Conversion.new(self, variant, row).run!
    end
  end

  def attribute_groups_of(row)
    row.attribute_groups
  rescue ActiveRecord::SerializationTypeMismatch => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not an array (#{e.message})"
  rescue Psych::Exception => e
    raise Unconvertible, "type_variants ##{row.id}: attribute_groups is not parseable (#{e.message})"
  end

  def generate_defaults!(variant)
    result = WorkPackageTypes::FormConfiguration::GenerateDefaultsService.new(variant).call
    return if result.success?

    raise Unconvertible,
          "type_variants ##{variant.id}: defaults not generated (#{result.errors.full_messages.to_sentence})"
  end

  # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
  class Conversion
    def initialize(migration, variant, row)
      @migration = migration
      @variant = variant
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
      WorkPackageTypes::FormConfiguration::ReconcileAttributesService.new(variant).call
      prune_required_attributes!
      verify!
    end

    private

    attr_reader :migration, :variant, :row

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

    # Runs before anything is named, so a dropped group consumes neither an untitled number nor
    # a default key on either the conversion or the expectation side.
    def drop_missing_query_groups(tuples)
      tuples.reject do |key, members, _|
        query_id = BackfillFormConfigurationRecords.query_group_id(members)
        next false if query_id.nil? || Query.exists?(query_id)

        log("dropped query group #{key.inspect} referencing missing query_#{query_id}")
        true
      end
    end

    def convert_tuple!(tuple)
      key, members, display_name = tuple
      query_id = BackfillFormConfigurationRecords.query_group_id(members)

      if query_id
        convert_query_group!(key, query_id, display_name)
      else
        convert_attribute_group!(key, members, display_name)
      end
    end

    def convert_query_group!(key, query_id, display_name)
      if FormConfigurationGroup.exists?(query_id:)
        query_id = rebuild_shared_query!(key, query_id)
        @expected[variant.form_groups.count][1] = [:"query_#{query_id}"]
      end

      variant.form_groups.create!(kind: FormConfigurationGroup::QUERY, query_id:, **group_naming(key, display_name))
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
      group = variant.form_groups.create!(kind: FormConfigurationGroup::ATTRIBUTE, **group_naming(key, display_name))
      members.each { |member| place_member!(group, member) }
    end

    def group_naming(key, display_name)
      if key.is_a?(Symbol) && variant.form_groups.where(default_key: key.to_s).none?
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
      variant.form_attributes.create!(group:, position: group.members.count + 1, **reference)
    end

    def drop_expected_member!(group, key)
      index = variant.form_groups.reload.index(group)
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
      actual = variant.form_groups.reload.map do |group|
        key = group.default_key ? group.default_key.to_sym : group.label
        members = group.query? ? [:"query_#{group.query_id}"] : group.members.map(&:key)
        [key, members]
      end

      return if actual == @expected

      unconvertible!("verification failed, expected #{@expected.inspect} but stored #{actual.inspect}")
    end

    def log(message)
      migration.say("type_variants ##{variant.id}: #{message}")
    end

    def unconvertible!(reason)
      raise Unconvertible, "type_variants ##{variant.id}: #{reason}"
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
        query_id = BackfillFormConfigurationRecords.query_group_id(members)
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
