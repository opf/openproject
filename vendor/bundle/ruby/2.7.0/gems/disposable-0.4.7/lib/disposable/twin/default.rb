require "declarative/option"

# TODO: allow default: -> for hashes, etc.
module Disposable::Twin::Default
  def setup_value_for(dfn, options)
    value = super
    return value unless value.nil?
    default_for(dfn, options)
  end

  def default_for(dfn, options)
    # TODO: introduce Null object in Declarative::Definition#[].
    # dfn[:default].(self) # dfn#[] should return a Null object here if empty.
    return unless dfn[:default]
    dfn[:default].(self)
  end

  module ClassMethods
  private
    def build_definition(name, options={}, &block)
      options = options.merge(default: Declarative::Option(options[:default], instance_exec: true)) if options.has_key?(:default)
      super
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
