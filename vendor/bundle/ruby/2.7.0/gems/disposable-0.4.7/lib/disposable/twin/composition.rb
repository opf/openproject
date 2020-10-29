require "disposable/expose"
require "disposable/composition"

module Disposable
  class Twin
    module Expose
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Expose).from(definitions.values)
        end
      end # ClassMethods.

      def self.included(base)
        base.extend(ClassMethods)
      end

      module Initialize
        def mapper_for(*args)
          self.class.expose_class.new(*args)
        end
      end
      include Initialize
    end


    module Composition
      module ClassMethods
        def expose_class
          @expose_class ||= Class.new(Disposable::Composition).from(definitions.values)
        end
      end

      def self.included(base)
        base.send(:include, Expose::Initialize)
        base.extend(ClassMethods)
      end

      def to_nested_hash(*)
        hash = {}

        @model.each do |name, model| # TODO: provide list of composee attributes in Composition.
          part_properties = schema.find_all { |dfn| dfn[:on] == name }.collect{ |dfn| dfn[:name].to_sym }
          hash[name] = self.class.nested_hash_representer.new(self).to_hash(include: part_properties)
        end

        hash
      end

    private
      def save_model
        res = true
        mapper.each { |twin| res &= twin.save } # goes through all models in Composition.
        res
      end
    end
  end
end
