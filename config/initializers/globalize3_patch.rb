# this is a pull request on globalize 3
# https://github.com/svenfuchs/globalize3/pull/139
# which is based on
# https://github.com/svenfuchs/globalize3/pull/121
# does not work on rails 3.0 as it depends on build_relation but will on 3.1

require 'active_record/validations/uniqueness.rb'

ActiveRecord::Validations::UniquenessValidator.class_eval do
  def validate_each_with_translations(record, attribute, value)
    klass = record.class
    if klass.translates? && klass.translated?(attribute)
      finder_class = klass.translation_class
      table = finder_class.arel_table

      relation = build_relation(finder_class, table, attribute, value).and(table[:locale].eq(Globalize.locale))
      relation = relation.and(table[klass.reflect_on_association(:translations).foreign_key].not_eq(record.send(:id))) if record.persisted?

      translated_scopes = Array(options[:scope]) & klass.translated_attribute_names
      untranslated_scopes = Array(options[:scope]) - translated_scopes

      untranslated_scopes.each do |scope_item|
        scope_value = record.send(scope_item)
        reflection = klass.reflect_on_association(scope_item)
        if reflection
          scope_value = record.send(reflection.foreign_key)
          scope_item = reflection.foreign_key
        end
        relation = relation.and(find_finder_class_for(record).arel_table[scope_item].eq(scope_value))
      end

      translated_scopes.each do |scope_item|
        scope_value = record.send(scope_item)
        relation = relation.and(table[scope_item].eq(scope_value))
      end

      if klass.unscoped.with_translations.where(relation).exists?
        record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
      end
    else
      validate_each_without_translations(record, attribute, value)
    end
  end
  alias_method_chain :validate_each, :translations
end

module Globalize
  module ActiveRecord
    module AdapterPatch
      module ClassMethods
      end

      module InstanceMethods
        def stash_to_cache
          @cache = @stash.dup
        end

        protected

        def cache=(cache)
          @cache = cache
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end

module GlobalizePatch
  module ClassMethods
    # Executes block without cached translations.
    def without_cache_for(object)
      current_cache = object.globalize.cache
      object.globalize.stash_to_cache
      yield
    ensure
      object.globalize.send(:cache=, current_cache)
    end
  end

  module InstanceMethods
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end

Globalize.send(:include, GlobalizePatch)
Globalize::ActiveRecord::Adapter.send(:include, Globalize::ActiveRecord::AdapterPatch)

