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
      # Wiki Link Transformer
      #
      # Examples:
      #   [[mypage]]
      #   [[mypage|mytext]]
      # wiki links can refer other project wikis, using project name or identifier:
      #   [[project:]] -> wiki starting page
      #   [[project:|mytext]]
      #   [[project:mypage]]
      #   [[project:mypage|mytext]]
      class WikiLinkTransformer < TextTransformer
        def process(fragment, options)
          result = Nokogiri::XML.fragment ''
          project = options[:project]
          fragment.children.each do |node|
            if node.text?
              text = node.to_s.gsub(/(!)?(\[\[([^\]\n\|]+)(\|([^\]\n\|]+))?\]\])/) do |_m|
                link_project = project
                esc = $1
                all = $2
                page = $3
                title = $5
                if esc.nil?
                  if page =~ /\A([^\:]+)\:(.*)\z/
                    link_project = Project.find_by(identifier: $1) || Project.find_by(name: $1)
                    page = $2
                    title ||= $1 if page.blank?
                  end

                  if link_project && link_project.wiki
                    # extract anchor
                    anchor = nil
                    if page =~ /\A(.+?)\#(.+)\z/
                      page = $1
                      anchor = $2
                    end
                    # Unescape the escaped entities from textile
                    page = CGI.unescapeHTML(page)
                    # check if page exists
                    wiki_page = link_project.wiki.find_page(page)
                    wiki_title = wiki_page.nil? ? page : wiki_page.title
                    url = case options[:wiki_links]
                            when :local; "#{title}.html"
                            when :anchor; "##{title}"   # used for single-file wiki export
                            else
                              wiki_page_id = wiki_page.nil? ? page.to_url : wiki_page.slug
                              url_for(only_path: only_path, controller: '/wiki', action: 'show',
                                      project_id: link_project, id: wiki_page_id, anchor: anchor)
                          end
                    link_to(h(title || wiki_title), url, class: ('wiki-page' + (wiki_page ? '' : ' new')))
                  else
                    # project or wiki doesn't exist
                    all
                  end
                else
                  all
                end
              end
              result.add_child Nokogiri::XML.fragment text
            else
              result.add_child node
            end
          end
          return result
        end
      end
    end
  end
end
