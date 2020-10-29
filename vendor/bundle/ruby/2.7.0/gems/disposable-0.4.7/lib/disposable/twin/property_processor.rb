# This is similar to Representable::Serializer and allows to apply a piece of logic (the
# block passed to #call) to every twin for this property.
#
# For a scalar property, this will be run once and yield the property's value.
# For a collection, this is run per item and yields the item.
#:private:
class Disposable::Twin::PropertyProcessor
  def initialize(definition, twin, value=nil)
    value     ||= twin.send(definition.getter) # DISCUSS: should we decouple definition and value, here?
    @definition = definition
    @value      = value
  end

  def call(&block)
    if @definition[:collection]
      collection!(&block)
    else
      property!(&block)
    end
  end

private
  def collection!
    (@value || []).each_with_index.collect { |nested_twin, i| yield(nested_twin, i) }
  end

  def property!
    twin = @value or return nil
    yield(twin)
  end
end
