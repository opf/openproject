module Delayed
  class PerformableMethod
    # serialize to YAML
    def encode_with(coder)
      coder.map = {
        'object' => object,
        'method_name' => method_name,
        'args' => args
      }
    end
  end
end

module Psych
  def self.load_dj(yaml)
    result = parse(yaml)
    result ? Delayed::PsychExt::ToRuby.create.accept(result) : result
  end
end

module Delayed
  module PsychExt
    class ToRuby < Psych::Visitors::ToRuby
      unless respond_to?(:create)
        def self.create
          new
        end
      end

      def visit_Psych_Nodes_Mapping(object) # rubocop:disable CyclomaticComplexity, MethodName, PerceivedComplexity
        klass = Psych.load_tags[object.tag]
        if klass
          # Implementation changed here https://github.com/ruby/psych/commit/2c644e184192975b261a81f486a04defa3172b3f
          # load_tags used to have class values, now the values are strings
          klass = resolve_class(klass) if klass.is_a?(String)
          return revive(klass, object)
        end

        case object.tag
        when %r{^!ruby/object}
          result = super
          if jruby_is_seriously_borked && result.is_a?(ActiveRecord::Base)
            klass = result.class
            id = result[klass.primary_key]
            begin
              klass.unscoped.find(id)
            rescue ActiveRecord::RecordNotFound => error # rubocop:disable BlockNesting
              raise Delayed::DeserializationError, "ActiveRecord::RecordNotFound, class: #{klass}, primary key: #{id} (#{error.message})"
            end
          else
            result
          end
        when %r{^!ruby/ActiveRecord:(.+)$}
          klass = resolve_class(Regexp.last_match[1])
          payload = Hash[*object.children.map { |c| accept c }]
          id = payload['attributes'][klass.primary_key]
          id = id.value if defined?(ActiveRecord::Attribute) && id.is_a?(ActiveRecord::Attribute)
          begin
            klass.unscoped.find(id)
          rescue ActiveRecord::RecordNotFound => error
            raise Delayed::DeserializationError, "ActiveRecord::RecordNotFound, class: #{klass}, primary key: #{id} (#{error.message})"
          end
        when %r{^!ruby/Mongoid:(.+)$}
          klass = resolve_class(Regexp.last_match[1])
          payload = Hash[*object.children.map { |c| accept c }]
          id = payload['attributes']['_id']
          begin
            klass.find(id)
          rescue Mongoid::Errors::DocumentNotFound => error
            raise Delayed::DeserializationError, "Mongoid::Errors::DocumentNotFound, class: #{klass}, primary key: #{id} (#{error.message})"
          end
        when %r{^!ruby/DataMapper:(.+)$}
          klass = resolve_class(Regexp.last_match[1])
          payload = Hash[*object.children.map { |c| accept c }]
          begin
            primary_keys = klass.properties.select(&:key?)
            key_names = primary_keys.map { |p| p.name.to_s }
            klass.get!(*key_names.map { |k| payload['attributes'][k] })
          rescue DataMapper::ObjectNotFoundError => error
            raise Delayed::DeserializationError, "DataMapper::ObjectNotFoundError, class: #{klass} (#{error.message})"
          end
        else
          super
        end
      end

      # defined? is triggering something really messed up in
      # jruby causing both the if AND else clauses to execute,
      # however if the check is run here, everything is fine
      def jruby_is_seriously_borked
        defined?(ActiveRecord::Base)
      end

      def resolve_class(klass_name)
        return nil if !klass_name || klass_name.empty?
        klass_name.constantize
      rescue
        super
      end
    end
  end
end
