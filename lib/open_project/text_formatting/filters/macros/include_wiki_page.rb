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

module OpenProject::TextFormatting::Filters::Macros
  module IncludeWikiPage
    HTML_CLASS = 'include_wiki_page'.freeze

    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, result:, context:)
      args = macro['data-page']
      raise I18n.t('macros.errors.missing_or_invalid_parameter') unless args.present?

      page = Wiki.find_page(args, project: context[:project])
      user = context[:current_user]

      if page.nil? || !user.allowed_to?(:view_wiki_pages, page.wiki.project)
        raise I18n.t('macros.include_wiki_page.errors.page_not_found', name: args)
      end

      # We remember the already included wiki pages in this run in:
      # - the result object for this current run
      # - the context of all contained inclusion runs, since result is reset in each pipeline instance.
      result[:included_wiki_pages] ||= context[:included_wiki_pages] || []
      if result[:included_wiki_pages].include?(args)
        raise I18n.t('macros.include_wiki_page.errors.circular_inclusion')
      end

      result[:included_wiki_pages] << args

      out = format_included_page(page, context, result)

      result[:included_wiki_pages].pop

      # Wrap result in section so we could, e.g., highlight it
      macro.replace ApplicationController.helpers.content_tag :section,
                                                              out,
                                                              class: 'macros--included-wiki-page',
                                                              data: { 'page-name': args }
    end

    ##
    # Format included wiki page
    def format_included_page(page, context, result)
      OpenProject::TextFormatting::Renderer.format_text(
        page.content.text,
        context.merge(
          included_wiki_pages: result[:included_wiki_pages],
          # Markdown handler currently does no inline_attachments_parsing. Still needed?
          attachments: page.attachments,
          headings: false
        )
      )
    end
  end
end
