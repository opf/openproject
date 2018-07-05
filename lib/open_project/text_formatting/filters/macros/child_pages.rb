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
  module ChildPages
    HTML_CLASS = 'child_pages'.freeze
    
    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, result:, context:)
      insert_child_pages(macro, context) if is?(macro)
    end

    def insert_child_pages(macro, context)
      page_value = macro['data-page']
      include_parent = macro['data-include-parent'].to_s == 'true'
      user = context[:current_user]
      page = nil
      if page_value.present?
        page = Wiki.find_page(page_value, project: context[:project])
      elsif context[:object].is_a?(WikiContent)
        page = context[:object].page
      end

      if page.nil? || !user.allowed_to?(:view_wiki_pages, page.wiki.project)
        raise I18n.t('macros.include_wiki_page.errors.page_not_found', name: page_value)
      end

      pages = ([page] + page.descendants).group_by(&:parent_id)
      pages_tree = ApplicationController.helpers.render_page_hierarchy(pages, include_parent ? page.parent_id : page.id)
      macro.replace(pages_tree)
    end

    def is?(macro)
      macro['class'].include?(HTML_CLASS)
    end
  end
end
