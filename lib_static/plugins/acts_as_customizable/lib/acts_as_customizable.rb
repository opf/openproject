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

module Redmine
  module Acts
    module Customizable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_customizable(options = {}) # rubocop:disable Metrics/AbcSize
          return if included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)

          send :include, Redmine::Acts::Customizable::InstanceMethods

          cattr_accessor :customizable_options
          self.customizable_options = options

          # We are validating custom_values manually in :validate_custom_values
          # N.B. the default for validate should be false, however specs seem to think differently
          has_many :custom_values, -> {
            includes(:custom_field)
              .order("#{CustomField.table_name}.position", "#{CustomValue.table_name}.id")
          }, as: :customized,
             dependent: :delete_all,
             validate: false,
             autosave: true

          if can_have_custom_comments?
            has_many :custom_comments,
                     as: :customized,
                     dependent: :delete_all,
                     autosave: true
          end

          validation_options = {}

          if options[:validate_on]
            validation_options[:on] = options[:validate_on]
          end

          if options[:validate_except_on]
            validation_options[:except_on] = options[:validate_except_on]
          end

          if options[:validate_if]
            validation_options[:if] = options[:validate_if]
          end

          if options[:validate_unless]
            validation_options[:unless] = options[:validate_unless]
          end

          validate :validate_custom_values, **validation_options

          before_save :ensure_custom_values_complete
          after_save :touch_customizable,
                     :reset_custom_values_change_tracker
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend AddClassMethods
          base.extend HumanAttributeName
        end

        def customizable?
          true
        end

        delegate :admin_only_custom_fields_allowed?,
                 :can_have_custom_comments?,
                 :custom_field_class,
                 to: :class

        def available_custom_fields
          self.class.available_custom_fields(self)
        end

        # Note:
        #
        # The role of this method is to provide flexibility on enabling just a subset of
        # available_custom_fields on the UI while enabling all_available_custom_fields via the api.
        # A good example is the Project's attributes, the UI allows the enabled attributes only,
        # and the Projects API still provides the old behaviour where all the custom fields are available.
        # Once the api behaviour is aligned to the UI behaviour, this method can be removed in favor of
        # the available_custom_fields method.
        def all_available_custom_fields
          @all_available_custom_fields ||= available_custom_fields
        end

        # Sets the values of the object's custom fields
        # values is an array like [{'id' => 1, 'value' => 'foo'}, {'id' => 2, 'value' => 'bar'}]
        def custom_fields=(values)
          values_to_hash = values.inject({}) do |hash, v|
            v = v.stringify_keys
            if v["id"] && v.has_key?("value")
              hash[v["id"]] = v["value"]
            end
            hash
          end
          self.custom_field_values = values_to_hash
        end

        # Sets the values of the object's custom fields
        # values is a hash like {'1' => 'foo', 2 => 'bar'}
        #
        # Also supports multiple values for a custom field where
        # instead of a single value you'd pass an array.
        def custom_field_values=(values)
          return unless values.is_a?(Hash) && values.any?

          values.stringify_keys.each do |custom_field_id, new_values|
            existing_cv_by_value = custom_values_for_custom_field(custom_field_id, all: true)
                                     .group_by(&:value)
                                     .transform_values(&:first)
            next if existing_cv_by_value.empty?

            update_custom_value(custom_field_id, existing_cv_by_value, new_values)
          end
        end

        def custom_comments=(values)
          raise ArgumentError, "Comments are not enabled for this customizable model" unless can_have_custom_comments?

          case values
          when Array
            super
          when Hash
            comments_by_field_id = custom_comments.index_by(&:custom_field_id)

            set_custom_comments(values:, comments_by_field_id:)
          else
            raise ArgumentError, "Expected an Array or Hash, got #{values.class}"
          end
        end

        def custom_values_for_custom_field(custom_field_or_id, all: false)
          id = custom_field_or_id.is_a?(CustomField) ? custom_field_or_id.id : custom_field_or_id.to_i

          custom_field_values(all:).select { |cv| cv.custom_field_id == id }
        end

        def custom_field_values(all: false) = cached_custom_field_values[all ? :all_available : :available]

        # Finds a comment for the given custom field using a Ruby finder.
        #
        # This method is expected to be used when more comments are needed, so it
        # uses ruby finder to avoid  N+1 queries when iterating over multiple custom
        # fields.
        def custom_comment_for(custom_field)
          return unless can_have_custom_comments?

          custom_comments.find { it.custom_field == custom_field }
        end

        # Override to extend the cache key for caching @custom_field_values_cache.
        #
        # In some cases, the implementing class has a changing list of custom field values
        # depending on certain attributes. When those attributes are changed, the cache can
        # be kept up to date by including them in the overridden custom_field_cache_key method.
        #
        # i.e.: The work package custom field values are changing based on the project_id and type_id.
        # The only way to keep the cache updated is to include those ids in the cache key.
        def custom_field_cache_key
          1
        end

        ##
        # Maps custom_values into a hash that can be passed to attributes
        # but keeps multivalue custom fields as array values
        def custom_value_attributes(all: false)
          custom_field_values(all:).each_with_object({}) do |cv, hash|
            key = cv.custom_field_id
            value = cv.value

            hash[key] =
              if (existing = hash[key])
                Array(existing) << value
              else
                value
              end
          end
        end

        def visible_custom_field_values
          custom_field_values.reject(&:admin_only?)
        end

        def custom_value_for(custom_field)
          raise ArgumentError, "Expected a CustomField, got #{custom_field.class}" unless custom_field.is_a?(CustomField)

          values = custom_field_values.select { |v| v.custom_field_id == custom_field.id }

          if custom_field.multi_value?
            values.sort_by { |v| v.id.to_i } # need to cope with nil
          else
            values.first
          end
        end

        def typed_custom_value_for(custom_field)
          cvs = custom_value_for(custom_field)

          case cvs
          when Array
            cvs.map(&:typed_value)
          when CustomValue
            cvs.typed_value
          else
            cvs
          end
        end

        def formatted_custom_value_for(custom_field)
          cvs = custom_value_for(custom_field)

          case cvs
          when Array
            cvs.map(&:formatted_value)
          when CustomValue
            cvs.formatted_value
          else
            cvs
          end
        end

        def ensure_custom_values_complete
          return unless custom_values.loaded? && (custom_values.any?(&:changed?) || custom_value_destroyed)

          self.custom_values = custom_field_values(all: true)
        end

        def reload(*args)
          reset_custom_values_change_tracker

          super
        end

        def reset_custom_values_change_tracker
          @custom_field_values_cache = nil
          @all_available_custom_fields = nil
          self.custom_value_destroyed = false
        end

        def reset_custom_values!
          reset_custom_values_change_tracker
          custom_values.each { |cv| cv.destroy unless custom_field_values.include?(cv) }
        end

        def custom_values_to_validate
          @custom_values_to_validate ||= persisted? ? [] : custom_field_values
        end

        def custom_values_to_validate=(custom_values)
          @custom_values_to_validate = Array(custom_values)
        end

        def validate_custom_values
          custom_values_to_validate
            .uniq
            .reject { |cv| cv.marked_for_destruction? || cv.calculated_value? }
            .select(&:invalid?)
            .each { |custom_value| add_custom_value_errors! custom_value }
        end

        def activate_custom_field_validations!
          self.custom_values_to_validate = custom_field_values
        end

        def deactivate_custom_field_validations!
          self.custom_values_to_validate = []
        end

        def custom_field_changes
          {}.tap do |changes|
            custom_value_changes(into: changes)
            custom_comment_changes(into: changes)
          end
        end

        # Build the changes hash similar to ActiveRecord::Base#changes,
        # but for the custom field values that have been changed.
        def custom_value_changes(into: {}) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          all_fields_grouped = custom_field_values.group_by(&:custom_field)

          all_fields_grouped.each_with_object(into) do |(custom_field, new_custom_field_values), changes|
            old_value = custom_value_was_for(custom_field)

            # Skip when only setting the default value
            next if old_value.blank? && new_custom_field_values.all?(&:default?)

            new_value = if custom_field.multi_value?
                          new_custom_field_values.filter_map(&:value).sort
                        else
                          new_custom_field_values.first&.value
                        end

            # Skip when the old value equals the new value (no change happened).
            next if old_value == new_value

            changes[custom_field.attribute_name] = [old_value, new_value]
          end
        end

        def custom_comment_changes(into: {})
          return into unless can_have_custom_comments?

          custom_comments.each_with_object(into) do |comment, changes|
            next unless comment.changed_for_autosave?

            changes[comment.custom_field.comment_attribute_name] = comment.text_change
          end
        end

        def changed_with_custom_fields
          changed + custom_field_changes.keys
        end

        def custom_value_was_for(custom_field)
          if custom_field.multi_value?
            all_old_custom_field_values(custom_field).filter_map(&:value).sort
          else
            all_old_custom_field_values(custom_field).first&.value
          end
        end

        def all_old_custom_field_values(custom_field)
          custom_values.select do |cv|
            (cv.marked_for_destruction? || !cv.new_record?) && cv.custom_field_id == custom_field.id
          end
        end

        def add_custom_value_errors!(custom_value)
          custom_value.errors.each do |error|
            name = custom_value.custom_field.attribute_name.to_sym

            details = error.details

            # Use the generated message by the custom field
            # as it may contain specific parameters (e.g., :too_long requires :count)
            errors.add(name, details[:error], **details.except(:error))
          end
        end

        def method_missing(method, *)
          for_custom_field_accessor(method) do |custom_field|
            add_custom_field_accessors(custom_field)
            return send(method, *)
          end

          super
        end

        def respond_to_missing?(method, include_private = false)
          super || for_custom_field_accessor(method) do |custom_field|
            # pro-actively add the accessors, the method will probably be called next
            add_custom_field_accessors(custom_field)
            return true
          end
        end

        def define_all_custom_field_accessors
          available_custom_fields.each do |custom_field|
            add_custom_field_accessors custom_field
          end
        end

        protected

        attr_accessor :custom_value_destroyed

        private

        def custom_field_values_cache
          @custom_field_values_cache ||= {}
        end

        def cached_custom_field_values
          custom_field_values_cache[custom_field_cache_key] ||= {
            all_available: uncached_custom_field_values_by_field(all_available_custom_fields),
            available: uncached_custom_field_values_by_field(available_custom_fields)
          }
        end

        def uncached_custom_field_values_by_field(custom_fields)
          custom_fields.flat_map do |custom_field|
            existing_cvs = custom_values.select { |v| v.custom_field_id == custom_field.id }

            if existing_cvs.empty?
              build_default_custom_values(custom_field)
            else
              existing_cvs
            end
          end
        end

        def build_default_custom_values(custom_field)
          if custom_field.multi_value? && custom_field.default_value.present?
            custom_field.default_value.map do |value|
              build_custom_value(custom_field, value:)
            end
          elsif custom_field.multi_value? && custom_field.default_value.blank?
            build_custom_value(custom_field, value: nil)
          else
            build_custom_value(custom_field, value: custom_field.default_value)
          end
        end

        def build_custom_value(custom_field, value:)
          custom_values.build(customized: self,
                              custom_field:,
                              value:)
        end

        def for_custom_field_accessor(method_symbol)
          return unless (id = method_symbol[/\Acustom_(?:field|comment)_(?<id>\d+)=?\z/, :id])
          return unless (custom_field = all_available_custom_fields.find { |cf| cf.id.to_s == id })

          yield custom_field
        end

        def add_custom_field_accessors(custom_field)
          define_custom_field_getters(custom_field)
          define_custom_field_setters(custom_field)
        end

        def define_custom_field_getters(custom_field)
          define_singleton_method custom_field.attribute_getter do
            custom_values = Array(custom_value_for(custom_field)).map do |custom_value|
              custom_value&.typed_value
            end

            if custom_field.multi_value?
              custom_values
            else
              custom_values.first
            end
          end

          define_singleton_method custom_field.comment_attribute_getter do
            custom_comment_for(custom_field)&.text
          end
        end

        def define_custom_field_setters(custom_field)
          define_singleton_method custom_field.attribute_setter do |value|
            # N.B. we do no strict type checking here, it would be possible to assign a user
            # to an integer custom field...
            value = value.id if value.respond_to?(:id)
            self.custom_field_values = { custom_field.id => Array(value) }
          end

          define_singleton_method custom_field.comment_attribute_setter do |text|
            self.custom_comments = { custom_field.id => text }
          end
        end

        # Explicitly touch the customizable if
        # there were only changes to custom_values (added or removed).
        # Particularly important for caching.
        def touch_customizable
          touch if !saved_changes? && custom_values.loaded? && (custom_values.any?(&:saved_changes?) || custom_value_destroyed)
        end

        def update_custom_value(custom_field_id, existing_cv_by_value, new_values)
          new_values = Array(new_values).map { |v| v.respond_to?(:id) ? v.id.to_s : v.to_s }

          assign_new_values(custom_field_id, existing_cv_by_value, new_values)
          delete_obsolete_custom_values(existing_cv_by_value, new_values)
          handle_minimum_custom_value(custom_field_id, existing_cv_by_value, new_values)
        end

        def assign_new_values(custom_field_id, existing_cv_by_value, new_values)
          (new_values - existing_cv_by_value.keys).each do |new_value|
            add_custom_value(custom_field_id, new_value)
          end
        end

        def delete_obsolete_custom_values(existing_cv_by_value, new_values)
          (existing_cv_by_value.keys - new_values).each do |obsolete_value|
            next if obsolete_value.nil?

            custom_value = existing_cv_by_value[obsolete_value]

            remove_custom_value(custom_value)
          end
        end

        # The original acts_as_customizable ensured to always have a custom value
        # for every custom field. If no value was set, the custom value would have the value of nil
        def handle_minimum_custom_value(custom_field_id, existing_cv_by_value, new_values)
          nil_value = existing_cv_by_value[nil]

          if new_values.any?
            remove_custom_value(nil_value)
          elsif nil_value.nil?
            add_custom_value(custom_field_id, nil)
          end
        end

        def add_custom_value(custom_field_id, value)
          new_custom_value = custom_values.build(customized: self,
                                                 custom_field_id:,
                                                 value:)

          cached_custom_field_values.each_value { it.push new_custom_value }
        end

        def remove_custom_value(custom_value)
          return unless custom_value

          custom_value.mark_for_destruction
          cached_custom_field_values.each_value { it.delete custom_value }
          self.custom_value_destroyed = true
        end

        def set_custom_comments(values:, comments_by_field_id:)
          values.each do |custom_field_id, text|
            # to_s is needed as in some cases custom_field_id will be a Symbol which doesn't have to_i method
            custom_field_id = custom_field_id.to_s.to_i
            comment = comments_by_field_id[custom_field_id]

            if comment
              comment.text = text.presence # for text_change also when removing
              comment.mark_for_destruction unless comment.text
            elsif text.present?
              custom_comments.build(custom_field_id:, text:)
            end
          end
        end

        module AddClassMethods
          def custom_field_class
            "#{name}CustomField".constantize
          rescue NameError
            nil
          end

          def available_custom_fields(_model)
            RequestStore.fetch(:"#{name.underscore}_custom_fields") do
              CustomField.where(type: "#{name}CustomField").order(:position)
            end
          end

          # TODO: move both settings from model level, as it is business logic?
          def admin_only_custom_fields_allowed? = customizable_options[:admin_only_allowed]
          def can_have_custom_comments? = customizable_options[:comments]
        end
      end

      def customizable?
        false
      end
    end
  end
end
