#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

module OpenProject
  module TextFormatting
    module Transformers
      class MacroTransformer < TextTransformer
        # pre process legacy macro syntax and replace it with the new syntax
        def pre_process(fragment, options)
          fragment
        end

        def process(fragment, options)
          # execute all in process macros
          result = Nokogiri::XML.fragment ''

          fragment.children.each do |node|
            if node.element? && node.name == 'opf:macro'
              result.add_child node
            else
              result.add_child node
            end
          end
          return result
        end

        def post_process(fragment, options)
          # execute all post processing macros
          fragment
        end
      end


      MACROS_RE = /
                  (!)?                        # escaping
                  (
                  \{\{                        # opening tag
                  ([\w]+)                     # macro name
                  (\(([^\}]*)\))?             # optional arguments
                  \}\}                        # closing tag
                  )
                /x unless const_defined?(:MACROS_RE)

# Macros substitution
      def execute_macros(text, project, obj, _attr, _only_path, options)
        return if !!options[:edit]
        text.gsub!(MACROS_RE) do
          esc = $1
          all = $2
          macro = $3
          args = ($5 || '').split(',').each(&:strip!)
          if esc.nil?
            begin
              exec_macro(macro, obj, args, view: self, project: project)
            rescue => e
              "<span class=\"flash error macro-unavailable permanent\">\
              #{::I18n.t(:macro_execution_error, macro_name: macro)} (#{e})\
            </span>".squish
            rescue NotImplementedError
              "<span class=\"flash error macro-unavailable permanent\">\
              #{::I18n.t(:macro_unavailable, macro_name: macro)}\
            </span>".squish
            end || all
          else
            all
          end
        end
      end

    end
  end
end
