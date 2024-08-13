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
        def acts_as_customizable(options = {})
          return if included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)

          cattr_accessor :customizable_options
          self.customizable_options = options

          # we are validating custom_values manually in :validate_custom_values
          # N.B. the default for validate should be false, however specs seem to think differently
          has_many :custom_values, -> {
            includes(:custom_field)
              .order("#{CustomField.table_name}.position")
          }, as: :customized,
             dependent: :delete_all,
             validate: false,
             autosave: true
          validate :validate_custom_values
          send :include, Redmine::Acts::Customizable::InstanceMethods

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

          values.with_indifferent_access.each do |custom_field_id, val|
            existing_cv_by_value = custom_values_for_custom_field(id: custom_field_id, all: true)
                                     .group_by(&:value)
                                     .transform_values(&:first)
            new_values = Array(val).map { |v| v.respond_to?(:id) ? v.id.to_s : v.to_s }

            if existing_cv_by_value.any?
              assign_new_values custom_field_id, existing_cv_by_value, new_values
              delete_obsolete_custom_values existing_cv_by_value, new_values
              handle_minimum_custom_value custom_field_id, existing_cv_by_value, new_values
            end
          end
        end

        def custom_values_for_custom_field(id:, all: false)
          custom_field_values(all:).select { |cv| cv.custom_field_id == id.to_i }
        end

        def custom_field_values(all: false)
          custom_field_values_cache[custom_field_cache_key] ||= begin
            current_custom_fields = all ? all_available_custom_fields : available_custom_fields
            current_custom_fields.flat_map do |custom_field|
              existing_cvs = custom_values.select { |v| v.custom_field_id == custom_field.id }

              if existing_cvs.empty?
                build_default_custom_values(custom_field)
              else
                existing_cvs
              end
            end
          end
        end

        # Override to extend the cache key for caching @custom_field_values_cache.
        #
        # In some cases, the implementing class has a changing list of custom field values
        # depending on certain attributes. When those attributes are changed, the cache can
        # be kept up to date by including them in the overriden custom_field_cache_key method.
        #
        # i.e.: The work package custom field values are changing based on the project_id and type_id.
        # The only way to keep the cache updated is to include those ids in the cache key.
        def custom_field_cache_key
          1
        end

        ##
        # Maps custom_values into a hash that can be passed to attributes
        # but keeps multivalue custom fields as array values
        def custom_value_attributes
          custom_field_values.each_with_object({}) do |cv, hash|
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

        def custom_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          values = custom_field_values.select { |v| v.custom_field_id == field_id }

          if values.size > 1
            values.sort_by { |v| v.id.to_i } # need to cope with nil
          else
            values.first
          end
        end

        def typed_custom_value_for(c)
          cvs = custom_value_for(c)

          case cvs
          when Array
            cvs.map(&:typed_value)
          when CustomValue
            cvs.typed_value
          else
            cvs
          end
        end

        def formatted_custom_value_for(c)
          cvs = custom_value_for(c)

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

          self.custom_values = custom_field_values
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

        # Builds custom values for all custom fields for which no custom value already exists.
        # The value of that newly build value is set to the default value which can also be nil.
        # Calling this should only be necessary if additional custom fields are made available
        # after custom_field_values has already been called as that method will also build custom values
        # (with their default values set) for all custom values for which no prior value existed.
        def set_default_values!
          new_values = {}

          available_custom_fields.each do |custom_field|
            if custom_values.none? { |cv| cv.custom_field_id == custom_field.id }
              new_values[custom_field.id] = custom_field.default_value
            end
          end

          self.custom_field_values = new_values
        end

        def custom_field_values_to_validate
          custom_field_values
        end

        def validate_custom_values
          set_default_values! if new_record?
          custom_field_values_to_validate
            .reject(&:marked_for_destruction?)
            .select(&:invalid?)
            .each { |custom_value| add_custom_value_errors! custom_value }
        end

        # Build the changes hash similar to ActiveRecord::Base#changes,
        # but for the custom field values that have been changed.
        def custom_field_changes
          custom_field_values.reduce({}) do |cfv_changes, cfv|
            next cfv_changes unless cfv.changed?

            # In order to construct a valid changes hash, we need to find the old value if it exists.
            # Otherwise set it to nil.
            cfv_was = custom_value_was_for(cfv)
            value_was = cfv_was&.value

            # Skip when the old value equals the new value (no change happened).
            next cfv_changes if value_was == cfv.value

            # Skip when the new value is the default value
            next cfv_changes if value_was.nil? && cfv.default?
            cfv_changes.merge("custom_field_#{cfv.custom_field_id}" => [value_was, cfv.value])
          end
        end

        def changed_with_custom_fields
          changed + custom_field_changes.keys
        end

        def custom_value_was_for(custom_value)
          custom_values.find do |cv|
            cv.marked_for_destruction? &&
            cv.custom_field_id == custom_value.custom_field_id
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
          match = /\Acustom_field_(?<id>\d+)=?\z/.match(method_symbol.to_s)
          if match
            custom_field = all_available_custom_fields.find { |cf| cf.id.to_s == match[:id] }
            if custom_field
              yield custom_field
            end
          end
        end

        def add_custom_field_accessors(custom_field)
          define_custom_field_getter(custom_field)
          define_custom_field_setter(custom_field)
        end

        def define_custom_field_getter(custom_field)
          define_singleton_method custom_field.attribute_getter do
            custom_values = Array(custom_value_for(custom_field)).map do |custom_value|
              custom_value ? custom_value.typed_value : nil
            end

            if custom_field.multi_value?
              custom_values
            else
              custom_values.first
            end
          end
        end

        def define_custom_field_setter(custom_field)
          define_singleton_method custom_field.attribute_setter do |value|
            # N.B. we do no strict type checking here, it would be possible to assign a user
            # to an integer custom field...
            value = value.id if value.respond_to?(:id)
            self.custom_field_values = { custom_field.id => Array(value) }
          end
        end

        # Explicitly touch the customizable if
        # there where only changes to custom_values (added or removed).
        # Particularly important for caching.
        def touch_customizable
          touch if !saved_changes? && custom_values.loaded? && (custom_values.any?(&:saved_changes?) || custom_value_destroyed)
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

          custom_field_values.push(new_custom_value)
        end

        def remove_custom_value(custom_value)
          return unless custom_value

          custom_value.mark_for_destruction
          custom_field_values.delete custom_value
          self.custom_value_destroyed = true
        end

        def custom_field_values_cache
          @custom_field_values_cache ||= {}
        end

        module AddClassMethods
          def available_custom_fields(_model)
            RequestStore.fetch(:"#{name.underscore}_custom_fields") do
              CustomField.where(type: "#{name}CustomField").order(:position)
            end
          end
        end
      end

      def customizable?
        false
      end
    end
  end
end
