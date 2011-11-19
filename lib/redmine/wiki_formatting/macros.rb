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

module Redmine
  module WikiFormatting
    module Macros
      module Definitions
        def exec_macro(name, obj, args)
          method_name = "macro_#{name}"
          send(method_name, obj, args) if respond_to?(method_name)
        end

        def extract_macro_options(args, *keys)
          options = {}
          while args.last.to_s.strip =~ %r{^(.+)\=(.+)$} && keys.include?($1.downcase.to_sym)
            options[$1.downcase.to_sym] = $2
            args.pop
          end
          return [args, options]
        end
      end

      @@available_macros = {}

      class << self
        # Called with a block to define additional macros.
        # Macro blocks accept 2 arguments:
        # * obj: the object that is rendered
        # * args: macro arguments
        #
        # Plugins can use this method to define new macros:
        #
        #   Redmine::WikiFormatting::Macros.register do
        #     desc "This is my macro"
        #     macro :my_macro do |obj, args|
        #       "My macro output"
        #     end
        #   end
        def register(&block)
          class_eval(&block) if block_given?
        end

      private
        # Defines a new macro with the given name and block.
        def macro(name, &block)
          name = name.to_sym if name.is_a?(String)
          @@available_macros[name] = @@desc || ''
          @@desc = nil
          raise "Can not create a macro without a block!" unless block_given?
          Definitions.send :define_method, "macro_#{name}".downcase, &block
        end

        # Sets description for the next macro to be defined
        def desc(txt)
          @@desc = txt
        end
      end
    end
  end
end
