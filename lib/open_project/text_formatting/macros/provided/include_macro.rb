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

  class IncludeMacro < OpenProject::TextFormatting::Macros::MacroBase

    descriptor do
      prefix :opf
      id :include
      desc <<-DESC
      Include the specified page.
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
        The id or name of the page.
        DESC
      end
      legacy_support
      stateful
    end

    def execute(args, object: nil, project: nil, **_options)
      refid = parse_args(args)

      # with no page given, Wiki.find_page will find the default page
      # causing an endless recursion
      raise 'No page specified' if refid.nil?

      including_page = determine_including_page(object)
      included_wiki_pages << including_page

      page = determine_page_to_include(refid, project)
      circular? refid, page, including_page

      do_include page
    rescue CircularInclusionError => error
      raise error
    rescue
      raise 'An error occurred when trying to include page ' +
            "`#{refid}'` in page `#{including_page}`"
    ensure
      # removing including page so that future runs will produce
      # reproducible results
      included_wiki_pages.pop
    end

    private

    def do_include(page)
      included_wiki_pages << page.title
      to_html page.content, :text, object: page, headings: false
    ensure
      included_wiki_pages.pop
    end

    def determine_including_page(object)
      unless object.nil? && object.respond_to?(:page)
        object.page.title
      else
        :unknown
      end
    end

    def determine_page_to_include(refid, project)
      result = Wiki.find_page(refid, project: project)
      if result.nil?
        raise "Page `#{refid}` not found"
      elsif !User.current.allowed_to?(:view_wiki_pages, result.wiki.project)
        raise "You are not permitted to view page `#{refid}`"
      end
      result
    end

    def circular?(refid, page, including_page)
      if included_wiki_pages.include?(page.title)
        raise CircularInclusionError,
          'Circular inclusion detected when trying to include page ' +
          "`#{refid}` in page `#{including_page}` via " +
          included_wiki_pages[0..-2].join(' -> ')
      end
    end

    def parse_args(args)
      if args.instance_of?(Hash)
        args[:page]
      else
        args[0]
      end
    end

    def included_wiki_pages
      state[:included_wiki_pages] ||= []
    end

    register!
  end

  class CircularInclusionError < RuntimeError
  end
end
