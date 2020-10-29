class Disposable::Twin
  module Save
    # Returns the result of that save invocation on the model.
    def save(options={}, &block)
      res = sync(&block)
      return res if block_given?

      save!(options)
    end

    def save!(options={})
      result = save_model

      schema.each(twin: true) do |dfn|
        next if dfn[:save] == false

        # call #save! on all nested twins.
        PropertyProcessor.new(dfn, self).() { |twin| twin.save! }
      end

      result
    end

    def save_model
      model.save
    end
  end
end