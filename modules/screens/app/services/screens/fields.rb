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
# frozen_string_literal: true

module Screens
  module Fields
    KEY_FORMAT = /\A[a-z_][a-z0-9_]{0,63}\z/
    CUSTOM_FIELD_KEY = /\Acustom_field_(\d+)\z/
    EXTRAS = %w[subject description status].freeze
    EXCLUDED = %w[id created_at updated_at author type project].freeze

    NATIVE_KEYS_CACHE = :screens_native_field_keys
    LABELS_CACHE = :screens_field_labels

    class << self
      def placeable?(key)
        key = key.to_s
        return false unless key.match?(KEY_FORMAT)
        return false if EXCLUDED.include?(key)
        return custom_field_exists?(key) if custom_field_id(key)

        native_keys.include?(key) || registry.key?(key)
      end

      # A field can be placed globally but be unavailable for a specific project/type, e.g. a
      # custom field that is not activated in that project. A missing variant fails open.
      def available?(key, project:, type:)
        variant = variant_of(project, type)
        return true if variant.nil?

        variant.passes_attribute_constraint?(key.to_s, project:)
      rescue StandardError
        true
      end

      def label(key)
        key = key.to_s
        custom_id = custom_field_id(key)
        if custom_id
          return labels[key] || WorkPackageCustomField.find_by(id: custom_id)&.name || key
        end

        labels[key].presence || WorkPackage.human_attribute_name(key)
      end

      def labels_for(keys)
        keys.index_with { |key| label(key) }
      end

      def register(key, label:)
        registry[key.to_s] = label.to_s
      end

      def reset_registry!
        @registry = {}
        RequestStore.store.delete(NATIVE_KEYS_CACHE) if defined?(RequestStore)
        RequestStore.store.delete(LABELS_CACHE) if defined?(RequestStore)
      end

      def custom_field_id(key)
        key.to_s[CUSTOM_FIELD_KEY, 1]&.to_i
      end

      def custom_field_key?(key)
        !custom_field_id(key).nil?
      end

      def native_keys
        if defined?(RequestStore)
          RequestStore.store[NATIVE_KEYS_CACHE] ||= compute_native_keys
        else
          @native_keys ||= compute_native_keys
        end
      end

      def native_labels
        keys = native_keys | registry.keys
        keys.index_with { |key| label(key) }
      end

      private

      def registry
        @registry ||= {}
      end

      def compute_native_keys
        base = TypeVariant.all_work_package_form_attributes.keys
        (base + EXTRAS - EXCLUDED).uniq.freeze
      end

      def labels
        if defined?(RequestStore)
          RequestStore.store[LABELS_CACHE] ||= compute_labels
        else
          @labels ||= compute_labels
        end
      end

      def compute_labels
        result = TypeVariant.translated_work_package_form_attributes
        EXTRAS.each { |key| result[key] ||= WorkPackage.human_attribute_name(key) }
        result
      end

      def custom_field_exists?(key)
        WorkPackageCustomField.exists?(id: custom_field_id(key))
      end

      def variant_of(project, type)
        return if project.nil? || type.nil?

        project.type_variant(type)
      end
    end
  end
end
