#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Macros::Provided
  class ChildPagesMacro < OpenProject::TextFormatting::Macros::MacroBase

    descriptor do
      prefix :opf
      id 'child-pages'
      desc <<-DESC
      Displays a list of child pages for a specific wiki page or the current page.
      DESC
      meta do
        provider 'OpenProject Foundation'
        url 'https://openproject.com'
        issues 'https://community.openproject.com'
        version 'TBD'
      end
      param do
        id :page
        desc <<-DESC
        Displays the child pages of the specified page.
        DESC
        optional
      end
      param do
        id :parent
        desc <<-DESC
        Includes a link to the parent page.
        DESC
        boolean
        optional
      end
      legacy_support { id :child_pages }
    end

    def execute(args, object: nil, project: nil, **_options)
      refid, parent = parse_args args
      page = determine_page refid, object, project

      if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
        raise "Page #{refid} not found"
      end
      pages = ([page] + page.descendants).group_by(&:parent_id)

      view.render_page_hierarchy(pages, parent ? page.parent_id : page.id)
    end

    private

    def determine_page(refid, object, project)
      if refid
        Wiki.find_page refid.to_s, project: project
      elsif object.is_a?(WikiContent)
        object.page
      else
        raise 'With no argument, this macro can be called from wiki pages only.'
      end
    end

    def parse_args(args)
      if args.instance_of?(Hash)
        [args[:page], args[:parent]]
      else
        args, options = Redmine::WikiFormatting::Macros::Definitions::extract_macro_options(
          args, :parent
        )
        [args[0], options[:parent]]
      end
    end

    register!
  end
end
