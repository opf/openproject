module Stringex
  module ActsAsUrl
    module Adapter
      class ActiveRecord < Base
        def self.load
          ensure_loadable
          orm_class.send :include, ActsAsUrlInstanceMethods
          orm_class.send :extend, ActsAsUrlClassMethods
        end

      private

        def klass_previous_instances(&block)
          klass.where(settings.url_attribute => [nil, '']).find_each(&block)
        end

        def self.orm_class
          ::ActiveRecord::Base
        end
      end
    end
  end
end