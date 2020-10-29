require "roar/http_verbs"

module Roar

  # Mix in HttpVerbs.
  module Client
    include HttpVerbs

    # Add accessors for properties and collections to modules.
    def self.extended(base)
      base.instance_eval do
        representable_attrs.each do |attr|
          name = attr.name
          next if name == "links" # ignore hyperlinks.

          # TODO: could anyone please make this better?
          instance_eval %Q{
            def #{name}=(v)
              @#{name} = v
            end

            def #{name}
              @#{name}
            end
          }
        end
      end
    end

    def to_hash(options={})
      # options[:links] ||= false
      options[:user_options] ||= {}
      options[:user_options][:links] ||= false

      super(options)
    end

    def to_xml(options={}) # sorry, but i'm not even sure if anyone uses this module.
      options[:user_options] ||= {}
      options[:user_options][:links] ||= false

      super(options)
    end
  end
end
