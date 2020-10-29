# Rescheme::from allows to copy a schema structure. This will create "fresh" inline schemas instead
# of inheriting/copying the original classes, making it a replication of the structure, only.
#
# Options allow to customize the copied schema.
#
# +:exclude+: ignore options from original Definition when copying.
#
# Provided block is run per newly created Definition.
#   Rescheme.from(...) { |dfn| dfn[:readable] = true }
class Disposable::Rescheme
  def self.from(*args, &block)
    new.from(*args, &block)
  end

  # Builds a new representer (structure only) from source_class.
  def from(source_class, options, &block) # TODO: can we re-use this for all the decorator logic in #validate, etc?
    representer = build_representer(options)

    definitions = options[:definitions_from].call(source_class)

    definitions.each do |dfn|
      next if (options[:exclude_properties]||{}).include?(dfn[:name].to_sym)

      dfn = build_definition!(options, dfn, representer, &block)
      evaluate_block!(options, dfn, &block)
    end

    representer
  end

private
  def build_representer(options)
    Class.new(options[:superclass]) { include(*options[:include]) }
  end

  def build_definition!(options, source_dfn, representer, &block)
    local_options = source_dfn[options[:options_from]] || {} # e.g. deserializer: {..}.

    new_options   = source_dfn.instance_variable_get(:@options).dup # copy original options.
    exclude!(options, new_options)
    new_options.merge!(local_options)

    return from_scalar!(options, source_dfn, new_options, representer) if options[:recursive]==false
    return from_scalar!(options, source_dfn, new_options, representer) unless source_dfn[:nested]
    from_inline!(options, source_dfn, new_options, representer, &block)
  end

  def exclude!(options, dfn_options)
    (options[:exclude_options] || []).each do |excluded|
      dfn_options.delete(excluded)
    end
  end

  def from_scalar!(options, dfn, new_options, representer)
    representer.property(dfn[:name], new_options)
  end

  def from_inline!(options, dfn, new_options, representer, &block)
    nested      = dfn[:nested]#.evaluate(nil) # nested now can be a Decorator, a representer module, a Form, a Twin.
    dfn_options = new_options.merge(nested: from(nested, options, &block))

    representer.property(dfn[:name], dfn_options)
  end

  def evaluate_block!(options, definition)
    return unless block_given?
    yield definition
  end
end