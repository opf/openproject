module Stringex
  module ActsAsUrl
    module Adapter
      class Mongoid < Base
        def self.load
          ensure_loadable
          orm_class.send :extend, Stringex::ActsAsUrl::ActsAsUrlClassMethods
        end

      private

        def add_new_record_url_owner_conditions
          return if instance.new_record?
          @url_owner_conditions.merge! id: {'$ne' => instance.id}
        end

        def add_scoped_url_owner_conditions
          [settings.scope_for_url].flatten.compact.each do |scope|
            @url_owner_conditions.merge! scope => instance.send(scope)
          end
        end

        def get_base_url_owner_conditions
          @url_owner_conditions = {settings.url_attribute => /^#{Regexp.escape(base_url)}/}
        end

        def klass_previous_instances(&block)
          klass.all(settings.url_attribute => [nil]).to_a.each(&block)
        end

        def self.orm_class
          ::Mongoid::Document
        end
      end
    end
  end
end
