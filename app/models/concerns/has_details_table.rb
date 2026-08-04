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

module HasDetailsTable
  extend ActiveSupport::Concern

  class_methods do
    # Declares a detail table for this model.
    # The detail model class is generated automatically — no separate file needed.
    #
    # The block is evaluated in the context of the generated detail class,
    # so you can declare associations, validations, callbacks, etc.
    #
    # The back-reference belongs_to, uniqueness constraint, and attribute
    # delegation are set up automatically.
    #
    # +foreign_key+ defaults to the Rails convention (<model_name>_id).
    # Override for STI or other cases where the FK doesn't match.
    #
    # Example:
    #   has_details_table do
    #     belongs_to :parent, class_name: "Group", optional: true
    #     validates :parent, presence: true, if: -> { parent_id.present? }
    #   end
    #
    def has_details_table(foreign_key: "#{model_name.element}_id", &) # rubocop:disable Naming/PredicatePrefix
      foreign_key = foreign_key.to_s

      detail_class = build_detail_class(foreign_key, &)
      association_name = detail_class.name.underscore.to_sym

      setup_detail_association(association_name, detail_class, foreign_key)
      setup_detail_aliases(association_name)
      setup_detail_delegation(detail_class, foreign_key)
      setup_detail_changed_tracking(detail_class, foreign_key)
      setup_detail_dup
    end

    private

    def build_detail_class(foreign_key, &block)
      owner_name = model_name.element.to_sym # e.g. :group
      fk = foreign_key

      klass = Class.new(ApplicationRecord) do
        belongs_to owner_name,
                   inverse_of: :"#{owner_name}_detail",
                   foreign_key: fk

        validates owner_name, presence: true, uniqueness: true

        class_eval(&block) if block
      end

      # Register as a named constant so it appears in stack traces, queries, etc.
      Object.const_set("#{name}Detail", klass)
    end

    def setup_detail_association(association_name, detail_class, foreign_key) # rubocop:disable Metrics/AbcSize
      has_one association_name, foreign_key:,
                                dependent: :destroy,
                                inverse_of: model_name.element.to_sym,
                                class_name: detail_class.name,
                                autosave: true
      accepts_nested_attributes_for association_name

      scope :with_detail, -> { joins(association_name).includes(association_name) }

      scope :where_detail, ->(**conditions) {
        joins(association_name).where(detail_class.table_name => conditions)
      }

      # Validate the detail record and promote its errors onto the owner
      # so they appear as direct attributes (e.g. group.errors[:parent]).
      validate do
        next if detail.nil? || detail.valid?

        detail.errors.each do |error|
          errors.add(error.attribute, error.type, message: error.message)
        end
      end

      # Auto-build the detail record so it's never nil
      after_initialize do
        build_detail if new_record? && detail.nil?
      end
    end

    def setup_detail_aliases(association_name)
      alias_method :detail, association_name
      alias_method :detail=, :"#{association_name}="
      alias_method :build_detail, :"build_#{association_name}"
    end

    # Include detail column changes in the owner's `changed` and `changes` so
    # that ModelContract can detect unauthorized writes to delegated attributes.
    def setup_detail_changed_tracking(detail_class, foreign_key)
      setup_changed_method(detail_class, foreign_key)
      setup_changes_method(detail_class, foreign_key)
      setup_changed_question_method(detail_class, foreign_key)
      setup_changed_attributes_method(detail_class, foreign_key)
      setup_previous_changes_method(detail_class, foreign_key)
      setup_restore_attributes_method(detail_class, foreign_key)
      setup_reload_method

      # Rails 5.1+ alias - only define if the original method exists
      alias_method :saved_changes, :previous_changes if method_defined?(:saved_changes)
    end

    def setup_changed_method(detail_class, foreign_key)
      define_method(:changed) do
        result = super()
        return result unless detail&.persisted?

        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns
        result | (detail.changed & detail_columns)
      end
    end

    def setup_changes_method(detail_class, foreign_key)
      define_method(:changes) do
        result = super()
        return result unless detail&.persisted?

        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns
        detail_changes = detail.changes.slice(*detail_columns)
        result.merge(detail_changes)
      end
    end

    def setup_changed_question_method(detail_class, foreign_key) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      define_method(:changed?) do |attr = nil| # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns

        if attr.nil?
          return true if super()
          return false unless detail&.persisted?

          detail.changed.intersect?(detail_columns)
        else
          attr = attr.to_s
          if detail_columns.include?(attr)
            detail.persisted? && detail.changed.include?(attr)
          else
            return false unless super()

            changed.include?(attr)
          end
        end
      end
    end

    def setup_changed_attributes_method(detail_class, foreign_key)
      define_method(:changed_attributes) do
        result = super()
        return result unless detail&.persisted?

        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns
        detail_changed = detail.changed_attributes.slice(*detail_columns)
        result.merge(detail_changed)
      end
    end

    def setup_previous_changes_method(detail_class, foreign_key)
      define_method(:previous_changes) do
        result = super()
        return result unless detail&.persisted?

        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns
        detail_previous = detail.previous_changes.slice(*detail_columns)
        result.merge(detail_previous)
      end
    end

    def setup_restore_attributes_method(detail_class, foreign_key)
      define_method(:restore_attributes) do |attributes = changed|
        attributes = Array(attributes).map(&:to_s)
        internal_columns = %w[id created_at updated_at] + [foreign_key]
        detail_columns = detail_class.column_names - internal_columns
        owner_attrs = attributes - detail_columns
        detail_attrs = attributes & detail_columns

        super(owner_attrs) if owner_attrs.any?
        detail.restore_attributes(detail_attrs) if detail_attrs.any? && detail&.persisted?
      end
    end

    def setup_reload_method
      define_method(:reload) do |*args|
        result = super(*args)
        detail&.reload
        result
      end
    end

    def setup_detail_delegation(detail_class, foreign_key)
      # Try to set up delegation eagerly so that writer methods exist
      # during assign_attributes in new/create. Requires DB + table.
      if ActiveRecord::Base.connected? && detail_class.table_exists?
        finalize_detail_delegation!(detail_class, foreign_key)
      end

      # Fallback for when eager setup was skipped (db:create, db:migrate).
      # finalize_detail_delegation! is idempotent via @_detail_delegation_set_up.
      fk = foreign_key
      after_initialize do
        self.class.send(:finalize_detail_delegation!, detail_class, fk)
      end
    end

    # AR's dup doesn't copy associations, so the detail would be lost.
    # Duplicate it so the copy behaves like a normal AR dup with all attributes.
    def setup_detail_dup
      define_method(:dup) do
        super().tap do |copy|
          copy.detail = detail.dup if detail.present?
        end
      end
    end

    # Defines a writer method that auto-builds the detail record.
    # This is necessary because `assign_attributes` runs before
    # `after_initialize`, so `allow_nil: true` delegation would
    # silently discard values when the detail hasn't been built yet.
    def define_detail_writer(writer)
      define_method(writer) do |value|
        record = detail || build_detail
        record.public_send(writer, value)
      end
    end

    def finalize_detail_delegation!(detail_class, foreign_key)
      return if @_detail_delegation_set_up
      # The detail table may not yet exist during early migrations on a fresh
      # database. Skip — the next instance will retry once the table is there.
      return unless ActiveRecord::Base.connected? && detail_class.table_exists?

      @_detail_delegation_set_up = true

      delegate_detail_columns(detail_class, foreign_key)
      delegate_detail_associations(detail_class)
    end

    def delegate_detail_columns(detail_class, foreign_key)
      internal_columns = %w[id created_at updated_at] + [foreign_key]

      (detail_class.column_names - internal_columns).each do |col|
        delegate col.to_sym, to: :detail
        define_detail_writer(:"#{col}=")

        if detail_class.columns_hash[col]&.type == :boolean
          delegate :"#{col}?", to: :detail
        end
      end
    end

    # Delegate belongs_to object readers/writers from the detail.
    # Column-level keys (e.g. parent_id) are already covered by delegate_detail_columns.
    def delegate_detail_associations(detail_class)
      detail_class.reflect_on_all_associations(:belongs_to).each do |reflection|
        next if reflection.name == model_name.element.to_sym # skip the back-reference

        delegate reflection.name, to: :detail
        define_detail_writer(:"#{reflection.name}=")
      end
    end
  end
end
