# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module Redmine
  module WikiFormatting
    module Macros
      module Definitions
        def exec_macro(name, obj, args)
          method_name = "macro_#{name}"
          send(method_name, obj, args) if respond_to?(method_name)
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
          
      # Builtin macros
      desc "Sample macro."
      macro :hello_world do |obj, args|
        "Hello world! Object: #{obj.class.name}, " + (args.empty? ? "Called with no argument." : "Arguments: #{args.join(', ')}")
      end
    
      desc "Displays a list of all available macros, including description if available."
      macro :macro_list do
        out = ''
        @@available_macros.keys.collect(&:to_s).sort.each do |macro|
          out << content_tag('dt', content_tag('code', macro))
          out << content_tag('dd', textilizable(@@available_macros[macro.to_sym]))
        end
        content_tag('dl', out)
      end
      
      desc "Displays a list of child pages."
      macro :child_pages do |obj, args|
        raise 'This macro applies to wiki pages only.' unless obj.is_a?(WikiContent)
        render_page_hierarchy(obj.page.descendants.group_by(&:parent_id), obj.page.id)
      end
      
      desc "Include a wiki page. Example:\n\n  !{{include(Foo)}}\n\nor to include a page of a specific project wiki:\n\n  !{{include(projectname:Foo)}}"
      macro :include do |obj, args|
        project = @project
        title = args.first.to_s
        if title =~ %r{^([^\:]+)\:(.*)$}
          project_identifier, title = $1, $2
          project = Project.find_by_identifier(project_identifier) || Project.find_by_name(project_identifier)
        end
        raise 'Unknow project' unless project && User.current.allowed_to?(:view_wiki_pages, project)
        raise 'No wiki for this project' unless !project.wiki.nil?
        page = project.wiki.find_page(title)
        raise "Page #{args.first} doesn't exist" unless page && page.content
        @included_wiki_pages ||= []
        raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
        @included_wiki_pages << page.title
        out = textilizable(page.content, :text, :attachments => page.attachments)
        @included_wiki_pages.pop
        out
      end
    end
  end
end
