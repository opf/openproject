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

# NOTE:this becomes obsolete once all existing legacy macros have been migrated to the new api
module Redmine
  module WikiFormatting
    module Macros
      module Definitions
        def self.extract_macro_options(args, *keys)
          warn '[DEPRECATION] `extract_macro_options` is deprecated.' +
               'Migrate your wiki macros to the new macro API.'
          options = {}
          while args.last.to_s.strip =~ %r{^(.+)\=(.+)$} && keys.include?($1.downcase.to_sym)
            options[$1.downcase.to_sym] = $2
            args.pop
          end
          [args, options]
        end

        def extract_macro_options(args, *keys)
          Definitions::extract_macro_options(args, *keys)
        end
      end

      def self.available_macros
        warn '[DEPRECATION] `available_macros` is deprecated. Use ' +
             '`OpenProject::TextFormatting::Macros::MacroRegistry.instance.registered_macros` ' +
             'instead.'
        OpenProject::TextFormatting::Macros::Internal::MacroRegistry.instance.registered_macros
      end

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
          warn '[DEPRECATION] `register` is deprecated.' +
               'Use `OpenProject::TextFormatting::Macros::MacroRegistry.instance.register` '
               'instead, and migrate your wiki macros to the new macro API.'
          class_eval(&block) if block_given?
        end

        private

        # Defines a new macro with the given name and block.
        def macro(name, &block)
          name = name.to_sym if name.is_a?(String)
          raise 'Can not create a macro without a block!' unless block_given?

          # register legacy macro with new macro registry
          OpenProject::TextFormatting::Macros::Internal::MacroRegistry
            .instance.register_legacy(name, @@desc || '', block)
        end

        # Sets description for the next macro to be defined
        def desc(txt)
          @@desc = txt
        end
      end
    end
  end
end
