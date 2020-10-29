require "uber/delegates"

module Disposable::Twin::Property
  module Unnest
    # TODO: test that nested properties options are "unnested", too, e.g. populator.
    def self.included(includer)
      includer.send(:include, Uber::Delegates)
    end

    def unnest(name, options)
      from = options.delete(:from)
      # needed to make reform process this field.

      options = definitions.get(from)[:nested].definitions.get(name).instance_variable_get(:@options) # FIXME.
      options = options.merge(virtual: true, _inherited: true, private_name: nil)

      property(name, options)
      delegates from, name, "#{name}="
    end
  end
end
