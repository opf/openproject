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

      desc "Displays a list of child pages. With no argument, it displays the child pages of the current wiki page. Examples:\n\n" +
             "  !{{child_pages}} -- can be used from a wiki page only\n" +
             "  !{{child_pages(Foo)}} -- lists all children of page Foo\n" +
             "  !{{child_pages(Foo, parent=1)}} -- same as above with a link to page Foo"
      macro :child_pages do |obj, args|
        args, options = extract_macro_options(args, :parent)
        page = nil
        if args.size > 0
          page = Wiki.find_page(args.first.to_s, :project => @project)
        elsif obj.is_a?(WikiContent)
          page = obj.page
        else
          raise 'With no argument, this macro can be called from wiki pages only.'
        end
        raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
        pages = ([page] + page.descendants).group_by(&:parent_id)
        render_page_hierarchy(pages, options[:parent] ? page.parent_id : page.id)
      end

      desc "Include a wiki page. Example:\n\n  !{{include(Foo)}}\n\nor to include a page of a specific project wiki:\n\n  !{{include(projectname:Foo)}}"
      macro :include do |obj, args|
        page = Wiki.find_page(args.first.to_s, :project => @project)
        raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
        @included_wiki_pages ||= []
        raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
        @included_wiki_pages << page.title
        out = textilizable(page.content, :text, :attachments => page.attachments, :headings => false)
        @included_wiki_pages.pop
        out
      end
    end
  end
end
