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

module OpenProject::TextFormatting::Formatters
  module Markdown
    class Helper
      attr_reader :view_context

      def initialize(view_context)
        @view_context = view_context
      end


      def text_formatting_js_includes
        view_context.javascript_include_tag 'vendor/ckeditor/ckeditor.js'
      end

      def text_formatting_has_preview?
        false
      end

      def wikitoolbar_for(field_id)
        if Setting.use_wysiwyg?
          wysiwyg_for field_id
        else
          jstoolbar_for field_id
        end
      end

      def self.initial_page_content(page)
        "# #{page.title}"
      end

      private

      def wysiwyg_for(field_id)
        view_context.content_tag 'op-ckeditor-form', '', 'textarea-selector': "##{field_id}"
      end

      def jstoolbar_for(field_id)
        view_context.content_for(:additional_js_dom_ready) do
          %(
              var wikiToolbar = new jsToolBar(document.getElementById('#{field_id}'));
              wikiToolbar.draw();
            ).html_safe
        end

        ''.html_safe
      end
    end
  end
end
