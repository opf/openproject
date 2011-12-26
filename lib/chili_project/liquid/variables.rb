#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ChiliProject
  module Liquid
    module Variables
      class LazyVariable
        def initialize(context, &block)
          @block = block
          @context = context
        end

        def to_liquid()
          (@block.arity == 0) ? @block.call : @block.call(@context)
        end
      end

      # Register a Liquid variable.
      # Pass a value to register a fixed variable or a block to create a lazy
      # evaluated variable. The block can take the current context
      def self.register(name, value=nil, &block)
        var = block_given? ? Proc.new(){|ctx| LazyVariable.new(ctx, &block)} : value
        all[name.to_s] = var
      end

      def self.all
        @variables ||= {}
      end

      register "tags" do
        ::Liquid::Template.tags.keys.sort
      end

      register "variables" do |context|
        vars = []

        vars = context.environments.first.keys.reject do |var|
          # internal variable
          var == "text"
        end if context.environments.present?
        vars += context.scopes.collect(&:keys).flatten
        vars.uniq.sort
      end

      # DEPRACATED: This is just a hint on how to use Liquid introspection
      register "macro_list",
        "Use '{{ variables | to_list: \"Variables:\" }}' to see all Liquid variables and '{{ tags | to_list: \"Tags:\" }}' to see all of the Liquid tags."
    end
  end
end
