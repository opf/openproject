#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::TextFormatting
  module Matchers
    # OpenProject wiki link syntax
    # Examples:
    #   [[mypage]]
    #   [[mypage|mytext]]
    # wiki links can refer other project wikis, using project name or identifier:
    #   [[project:]] -> wiki starting page
    #   [[project:|mytext]]
    #   [[project:mypage]]
    #   [[project:mypage|mytext]]
    class WikiLinksMatcher < RegexMatcher
      # Used for escaping helper 'h()'
      include ERB::Util
      # Rails helper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      # For route path helpers
      include OpenProject::ObjectLinking
      include OpenProject::StaticRouting::UrlHelpers

      def self.regexp
        /(!)?(\[\[([^\]\n|]+)(\|([^\]\n|]+))?\]\])/
      end

      def self.process_match(m, matched_string, context)
        # Leading string before match
        instance = new(
          matched_string:,
          escaped: m[1],
          all: m[2],
          page: m[3],
          title: m[5],
          context:
        )

        instance.process
      end

      attr_accessor :matched_string,
                    :escaped,
                    :all,
                    :page,
                    :title,
                    :project,
                    :context

      def initialize(matched_string:, escaped:, all:, page:, title:, context:)
        # The entire string that was matched
        @matched_string = matched_string

        # Catches the (!) to disable the parsing of this lnk
        @escaped = escaped

        # The entire wiki link when escaped
        @all = all

        # The wiki page to link
        @page = page

        # The title to print
        @title = title

        # Text formatting context
        @context = context

        # Check if linking project exists
        if page =~ /\A([^:]+):(.*)\z/
          @project = Project.find_by(identifier: $1) || Project.find_by(name: $1)
          @page = $2
          @title ||= $1 if @page.blank?
        else
          @project = context[:project]
        end
      end

      def process
        # When wiki link is escaped with ![[...]]
        # or link_project is missing,
        # return the whole match
        if escaped || !(project && project.wiki)
          return all
        end

        link_from_match
      end

      def link_from_match
        # extract anchor
        anchor = nil
        if page =~ /\A(.+?)\#(.+)\z/
          @page = $1
          anchor = $2
        end

        # Unescape the escaped entities from textile
        @page = CGI.unescapeHTML(page)

        # check if page exists
        wiki_page = project.wiki.find_page(page)
        default_wiki_title = wiki_page.nil? ? page : wiki_page.title
        wiki_title = title || default_wiki_title

        url = case context[:wiki_links]
              when :local
                "#{title}.html"
              when :anchor
                "##{title}" # used for single-file wiki export
              else
                wiki_page_id = wiki_page.nil? ? WikiPage.slug(page) : wiki_page.slug
                url_for(only_path: context[:only_path],
                        controller: "/wiki",
                        action: "show",
                        project_id: project.identifier,
                        title: wiki_page.nil? ? wiki_title.strip : nil,
                        id: wiki_page_id,
                        anchor:)
              end

        link_to h(wiki_title),
                url,
                class: ("wiki-page" + (wiki_page ? "" : " new"))
      end
    end
  end
end
