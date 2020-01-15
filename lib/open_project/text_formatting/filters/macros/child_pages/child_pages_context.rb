#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting::Filters::Macros::ChildPages
  class ChildPagesContext
    attr_reader(:page_value, :include_parent, :user, :page)

    def initialize(macro, pipeline_context)
      @page_value = macro['data-page']
      @include_parent = macro['data-include-parent'].to_s == 'true'
      @user = pipeline_context[:current_user]
      @page = fetch_page(pipeline_context)
    end

    def check
      if @page.nil? || !@user.allowed_to?(:view_wiki_pages, @page.wiki.project)
        raise I18n.t('macros.wiki_child_pages.errors.page_not_found', name: @page_value)
      end
    end

    private

    def fetch_page(pipeline_context)
      if page_value.present?
        Wiki.find_page(page_value, project: pipeline_context[:project])
      elsif pipeline_context[:object].is_a?(WikiContent)
        pipeline_context[:object].page
      end
    end
  end
end
