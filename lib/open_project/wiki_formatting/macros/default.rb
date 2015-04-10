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
  module WikiFormatting
    module Macros
      module Default
        Redmine::WikiFormatting::Macros.register do
          # Builtin macros

          desc 'Sample macro.'

          macro :hello_world do |obj, args|
            "Hello world! Object: #{obj.class.name}, " + (args.empty? ? 'Called with no argument.' : "Arguments: #{args.join(', ')}")
          end
        end

        Redmine::WikiFormatting::Macros.register do
          desc 'Displays a list of all available macros, including description if available.'
          macro :macro_list do |_obj, _args|
            out = ''
            available_macros = Redmine::WikiFormatting::Macros.available_macros

            available_macros.keys.map(&:to_s).sort.each do |macro|
              out << content_tag('dt', content_tag('code', macro))
              out << content_tag('dd', format_text(available_macros[macro.to_sym]))
            end
            content_tag('dl', out.html_safe)
          end
        end

        Redmine::WikiFormatting::Macros.register do
          desc "Displays a list of child pages. With no argument, it displays the child pages of the current wiki page. Examples:\n\n" +
            "  !{{child_pages}} -- can be used from a wiki page only\n" +
            "  !{{child_pages(Foo)}} -- lists all children of page Foo\n" +
            '  !{{child_pages(Foo, parent=1)}} -- same as above with a link to page Foo'

          macro :child_pages do |obj, args|
            args, options = extract_macro_options(args, :parent)
            page = nil
            if args.size > 0
              page = Wiki.find_page(args.first.to_s, project: @project)
            elsif obj.is_a?(WikiContent)
              page = obj.page
            else
              raise 'With no argument, this macro can be called from wiki pages only.'
            end
            raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
            pages = ([page] + page.descendants).group_by(&:parent_id)
            render_page_hierarchy(pages, options[:parent] ? page.parent_id : page.id)
          end

        end

        Redmine::WikiFormatting::Macros.register do
          desc "Include a wiki page. Example:\n\n  !{{include(Foo)}}\n\nor to include a page of a specific project wiki:\n\n  !{{include(projectname:Foo)}}"
          macro :include do |_obj, args|
            page = Wiki.find_page(args.first.to_s, project: @project)
            raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
            @included_wiki_pages ||= []
            raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
            @included_wiki_pages << page.title
            out = format_text(page.content, :text, attachments: page.attachments, headings: false)
            @included_wiki_pages.pop
            out
          end
        end

        Redmine::WikiFormatting::Macros.register do
          desc <<-EOF
            Display a timeline report on the Wiki page.
          EOF

          macro :timeline do |obj, args, options|
            OpenProject::WikiFormatting::Macros::TimelinesWikiMacro.new.apply obj, args, options.merge(view: self)
          end
        end
      end
    end
  end
end
