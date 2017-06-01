#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module WikiFormatting
    module Macros
      module Definitions
        def exec_macro(name, obj, args, options = {})
          method_name = "macro_#{name}"
          if respond_to?(method_name)
            if method(method_name).arity == 2
              send(method_name, obj, args)
            else
              send(method_name, obj, args, options)
            end
          end
        end

        def extract_macro_options(args, *keys)
          options = {}
          while args.last.to_s.strip =~ %r{^(.+)\=(.+)$} && keys.include?($1.downcase.to_sym)
            options[$1.downcase.to_sym] = $2
            args.pop
          end
          [args, options]
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

        def available_macros
          @@available_macros
        end

        private

        # Defines a new macro with the given name and block.
        def macro(name, &block)
          name = name.to_sym if name.is_a?(String)
          @@available_macros[name] = @@desc || ''
          @@desc = nil
          raise 'Can not create a macro without a block!' unless block_given?
          Definitions.send :define_method, "macro_#{name}".downcase, &block
        end

        # Sets description for the next macro to be defined
        def desc(txt)
          @@desc = txt
        end

        include OpenProject::WikiFormatting::Macros::Default
      end
    end
  end
end
