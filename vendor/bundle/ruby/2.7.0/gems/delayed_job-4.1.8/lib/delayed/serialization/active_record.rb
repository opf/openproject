if defined?(ActiveRecord)
  module ActiveRecord
    class Base
      yaml_tag 'tag:ruby.yaml.org,2002:ActiveRecord'

      def self.yaml_new(klass, _tag, val)
        klass.unscoped.find(val['attributes'][klass.primary_key])
      rescue ActiveRecord::RecordNotFound
        raise Delayed::DeserializationError, "ActiveRecord::RecordNotFound, class: #{klass} , primary key: #{val['attributes'][klass.primary_key]}"
      end

      def to_yaml_properties
        ['@attributes']
      end
    end
  end
end
