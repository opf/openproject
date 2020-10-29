module Disposable
  class Twin
    # Read all properties at twin initialization time from model.
    # Simply pass through all properties from the model to the respective twin writer method.
    # This will result in all twin properties/collection items being twinned, and collections
    # being Collection to expose the desired public API.
    module Setup
      def initialize(model, options={})
        @fields = {}
        @model  = model
        @mapper = mapper_for(model) # mapper for model.

        setup_properties!(options)
      end

    private
      def mapper_for(model)
        model
      end

      def setup_properties!(options)
        schema.each { |dfn| setup_property!(dfn, options) }
      end

      def setup_property!(dfn, options)
        if options.has_key?(dfn[:name].to_sym)
          value = options[dfn[:name].to_sym]
          return setup_write!(dfn, value)
        end

        value = setup_value_for(dfn, options)

        # this sucks and is why i introduce pipetrees in 0.4.
        return if dfn[:readable] == false && dfn[:default].nil?

        setup_write!(dfn, value) # note: even readable: false will be written to twin as nil.
      end

      def setup_value_for(dfn, options) # overridden by Default.
        return if dfn[:readable] == false
        read_value_for(dfn, options)
      end

      def read_value_for(dfn, options)
        mapper.send(dfn[:name]) # model.title.
      end

      def setup_write!(dfn, value)
        # send(dfn.setter, value)
        send("#{dfn[:name]}=", value) # FIXME!
      end

      # Including this will _not_ use the property's setter in Setup and allow you to override it.
      module SkipSetter
        def setup_write!(dfn, value)
          write_property(dfn[:name], value, dfn)
        end
      end
    end # Setup
  end
end
