module Stringex
  module ActsAsUrl
    module Adapter
      class DataMapper < Base
        def self.load
          ensure_loadable
          orm_class.send :include, Stringex::ActsAsUrl::ActsAsUrlInstanceMethods
          ::DataMapper::Model.send :include, Stringex::ActsAsUrl::ActsAsUrlClassMethods
        end

      private

        def create_callback
          klass.class_eval do
            before acts_as_url_configuration.settings.sync_url ? :save : :create, :ensure_unique_url
          end
        end

        def instance_from_db
          instance.class.get(instance.id)
        end

        def is_blank?(object)
          object.nil? || object == '' || object == []
        end

        def is_new?(object)
          object.new?
        end

        def is_present?(object)
          !is_blank? object
        end

        def klass_previous_instances(&block)
          klass.all(conditions: {settings.url_attribute => [nil]}).each(&block)
        end

        def primary_key
          instance.class.key.first.instance_variable_get '@name'
        end

        def url_owners
          @url_owners ||= url_owners_class.all(conditions: url_owner_conditions)
        end

        def read_attribute(instance, name)
          instance.attribute_get name
        end

        def write_attribute(instance, name, value)
          instance.attribute_set name, value
        end

        def self.orm_class
          ::DataMapper::Resource
        end
      end
    end
  end
end
